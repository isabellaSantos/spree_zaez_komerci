module Spree
  class PaymentMethod::Komerci < PaymentMethod

    def payment_source_class
      Spree::CreditCard
    end

    # Purchases the payment to Komerci
    #
    # @author Isabella Santos
    #
    # @return [ActiveMerchant::Billing::Response]
    #
    def purchase(_amount, source, gateway_options)
      if gateway_options[:portions].nil?
        return ActiveMerchant::Billing::Response.new(false, Spree.t('komerci.messages.invalid_portions'), {}, {})
      end

      if gateway_options[:portions] == 1
        transaction = '04'
        portions = '00'
      else
        transaction = Spree::KomerciConfig[:portions_type]
        portions = gateway_options[:portions]
      end

      params = prepare_authorize_params source, gateway_options
      params[:transacao] = transaction
      params[:parcelas] = portions

      response = Spree::KomerciConfig.authorize params

      verify_authorize_response(source, gateway_options, response, 'purchase')
    end

    # Authorizes the payment to Cielo
    #
    # @author Isabella Santos
    #
    # @return [ActiveMerchant::Billing::Response]
    #
    def authorize(_amount, source, gateway_options)
      if gateway_options[:portions].nil?
        return ActiveMerchant::Billing::Response.new(false, Spree.t('komerci.messages.invalid_portions'), {}, {})
      end

      params = prepare_authorize_params source, gateway_options
      params[:transacao] = '73'

      if gateway_options[:portions] == 1
        params[:parcelas] = '00'
      else
        params[:parcelas] = gateway_options[:portions]
      end

      response = Spree::KomerciConfig.authorize params

      verify_authorize_response(source, gateway_options, response, 'authorize')
    end

    # Captures the payment
    #
    # @author Isabella Santos
    #
    # @return [ActiveMerchant::Billing::Response]
    #
    def capture(amount, response_code, _gateway_options)
      total = sprintf('%0.2f', amount / 100)
      transaction = Spree::KomerciTransaction.find_by order_number: response_code

      if transaction.payment.portions == 1
        transaction_option = '04'
        portions = '00'
      else
        transaction_option = Spree::KomerciConfig[:portions_type]
        portions = transaction.payment.portions
      end

      params = {
          filiacao: Spree::KomerciConfig[:afiliation_key],
          total: total,
          transorig: transaction_option,
          parcelas: portions,
          data: transaction.created_at.strftime('%Y%m%d'),
          numautor: transaction.authorization_number,
          numcv: transaction.order_number,
          usr: Spree::KomerciConfig[:komerci_user],
          pwd: Spree::KomerciConfig[:komerci_password],
          distribuidor: nil,
          concentrador: nil
      }

      response = Spree::KomerciConfig.conf_authorize params

      if response[:success] == true
        ActiveMerchant::Billing::Response.new(true, Spree.t('komerci.messages.capture_success'), {}, authorization: response_code)
      else
        message = response[:data][:error_number] ? "#{response[:data][:error_number]}: " : ''
        message << response[:data][:error_message]
        ActiveMerchant::Billing::Response.new(false, message, {}, authorization: response_code)
      end
    end

    # Voids the payment
    #
    # @author Isabella Santos
    #
    # @return [ActiveMerchant::Billing::Response]
    #
    def void(response_code, _gateway_options)
      transaction = Spree::KomerciTransaction.find_by order_number: response_code

      params = {
          total: transaction.total,
          filiacao: Spree::KomerciConfig[:afiliation_key],
          numcv: transaction.order_number,
          numautor: transaction.authorization_number,
          usr: Spree::KomerciConfig[:komerci_user],
          pwd: Spree::KomerciConfig[:komerci_password],
          concentrador: nil
      }

      response = Spree::KomerciConfig.void_transaction params

      if response[:success] == true
        ActiveMerchant::Billing::Response.new(true, Spree.t('komerci.messages.void_success'), {}, authorization: response_code)
      else
        message = response[:data][:error_number] ? "#{response[:data][:error_number]}: " : ''
        message << response[:data][:error_message]
        ActiveMerchant::Billing::Response.new(false, message, {}, authorization: response_code)
      end
    end

    # Cancel the payment
    #
    # @author Isabella Santos
    #
    # @return [ActiveMerchant::Billing::Response]
    #
    def cancel(response_code)
      transaction = Spree::KomerciTransaction.find_by order_number: response_code

      params = {
          total: transaction.total,
          filiacao: Spree::KomerciConfig[:afiliation_key],
          numcv: transaction.order_number,
          numautor: transaction.authorization_number,
          usr: Spree::KomerciConfig[:komerci_user],
          pwd: Spree::KomerciConfig[:komerci_password],
          concentrador: nil
      }

      response = Spree::KomerciConfig.void_transaction params

      if response[:success] == true
        ActiveMerchant::Billing::Response.new(true, Spree.t('komerci.messages.cancel_success'), {}, authorization: response_code)
      else
        # Retorna como cancelado, mas avisando que o cancelamento deve ser feito no Portal
        ActiveMerchant::Billing::Response.new(true, Spree.t('komerci.messages.cancel_error_date'), {}, authorization: response_code)
      end
    end

    private

    # Returns the params to Komerci
    #
    # @author Isabella Santos
    #
    # @return [Hash]
    #
    def prepare_authorize_params(source, gateway_options)
      order_number, payment_number = gateway_options[:order_id].split('-')
      order = Spree::Order.friendly.find order_number
      payment = Spree::Payment.friendly.find payment_number
      portion_value = Spree::KomerciConfig.calculate_portion_value order, gateway_options[:portions]
      total_value = sprintf('%0.2f', portion_value * gateway_options[:portions])

      year = source.year.to_s.last(2)
      month = source.month.to_s.rjust(2, '0')

      params = {
          total: total_value,
          filiacao: Spree::KomerciConfig[:afiliation_key],
          numpedido: "#{order_number}-#{payment.id}",
          nrcartao: source.number,
          cvc2: source.verification_value,
          mes: month,
          ano: year,
          portador: source.name,
          conftxn: 'S'
      }

      [:iata, :distribuidor, :concentrador, :taxaembarque, :entrada, :adddata, :add_data,
       :numdoc1, :numdoc2, :numdoc3, :numdoc4, :pax1, :pax2, :pax3, :pax4].each { |p| params[p] = nil }

      params
    end

    # Update the value of the payment with the tax of the portions
    #
    # @author Isabella Santos
    #
    # @param gateway_options [Hash]
    #
    def update_payment_amount(gateway_options)
      order_number, payment_number = gateway_options[:order_id].split('-')
      order = Spree::Order.friendly.find order_number
      total = Spree::KomerciConfig.calculate_portion_value(order, gateway_options[:portions]) * gateway_options[:portions]

      if total > order.total
        Spree::Adjustment.create(adjustable: order,
                                 amount: (total - order.total),
                                 label: Spree.t(:komerci_adjustment_tax),
                                 eligible: true,
                                 order: order)
        order.updater.update

        payment = Spree::Payment.friendly.find payment_number
        payment.update_attributes(amount: order.total)

      end
    end

    # Verify if the response was authorized or not
    #
    # @author Isabella Santos
    #
    def verify_authorize_response(source, gateway_options, response, type)
      if response[:success]
        _order_number, payment_number = gateway_options[:order_id].split('-')
        payment = Spree::Payment.friendly.find payment_number

        update_payment_amount(gateway_options)

        komerci_attributes = response[:data].merge(credit_card_id: source.id,
                                                   payment_id: payment.id,
                                                   total: payment.reload.amount)
        Spree::KomerciTransaction.create(komerci_attributes)

        return ActiveMerchant::Billing::Response.new(true, Spree.t("komerci.messages.#{type}_success"), {}, authorization: response[:data][:order_number])
      else
        message = response[:data][:error_number] ? "#{response[:data][:error_number]}: " : ''
        message << response[:data][:error_message]

        return ActiveMerchant::Billing::Response.new(false, message, {}, authorization: '')
      end
    end

  end
end