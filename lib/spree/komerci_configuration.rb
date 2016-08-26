class Spree::KomerciConfiguration < Spree::Preferences::Configuration

  preference :afiliation_key,      :string,  default: ''       # afiliation key
  preference :komerci_user,        :string,  default: ''       # Komerci user
  preference :komerci_password,    :string,  default: ''       # Password of Komerci user
  preference :test_mode,           :boolean, default: false    # enable test mode
  preference :minimum_value,       :float,   default: 5.0      # minimum value per portion (minimum is 5.00)
  preference :tax_value,           :float,   default: 0.0      # tax value per month
  preference :max_portion,         :integer, default: 10       # quantity of portions supported
  preference :portion_without_tax, :integer, default: 1        # number of portions without tax
  preference :portions_type,       :string,  default: '06'     # (04 = a vista, 06 = parcelado emissor, 08 = parcelado estabelecimento )

  def authorize_uri
    if preferred_test_mode
      'https://ecommerce.userede.com.br/pos_virtual/wskomerci/cap_teste.asmx/GetAuthorizedTst'
    else
      'https://ecommerce.redecard.com.br/pos_virtual/wskomerci/cap.asmx/GetAuthorized'
    end
  end

  def conf_authorization_uri
    if preferred_test_mode
      'https://ecommerce.userede.com.br/pos_virtual/wskomerci/cap_teste.asmx/ConfPreAuthorizationTst'
    else
      'https://ecommerce.redecard.com.br/pos_virtual/wskomerci/cap.asmx/ConfPreAuthorization'
    end
  end

  def void_transaction_uri
    if preferred_test_mode
      'https://ecommerce.userede.com.br/pos_virtual/wskomerci/cap_teste.asmx/VoidTransactionTst'
    else
      'https://ecommerce.redecard.com.br/pos_virtual/wskomerci/cap.asmx/VoidTransaction'
    end
  end

  def authorize(params)
    response_xml = HTTParty.post(authorize_uri, body: params)
    response = Hash.from_xml response_xml.body.gsub("\r\n  ", '')
    response = format_keys(response)
    authorization = response[:authorization]

    if authorization[:codret] == '0' and authorization[:numcv]
      return {
          success: true,
          data: {
              authorization_number: authorization[:numautor],
              order_number: authorization[:numcv],
              authentication_number: authorization[:numautent],
              sequencial_number: authorization[:numsqn],
              bin: authorization[:origem_bin]
          }
      }
    else
      return {
          success: false,
          data: {
              error_number: authorization[:codret],
              error_message: authorization[:msgret]
          }
      }
    end
  rescue REXML::ParseException
    {
        success: false,
        data: {
            error_message: response_xml.body.gsub("\r\n", '')
        }
    }
  end

  def conf_authorize(params)
    response_xml = HTTParty.post(conf_authorization_uri, body: params)
    response = Hash.from_xml response_xml.body.gsub("\r\n  ", '')
    response = format_keys(response)
    confirmation = response[:confirmation][:root]

    if confirmation[:codret] == '0'
      return { success: true }
    else
      return {
          success: false,
          data: {
              error_number: confirmation[:codret],
              error_message: confirmation[:msgret]
          }
      }
    end
  rescue REXML::ParseException
    {
        success: false,
        data: {
            error_message: response_xml.body.gsub("\r\n", '')
        }
    }
  end

  def void_transaction params
    response_xml = HTTParty.post(void_transaction_uri, body: params)
    response = Hash.from_xml response_xml.body.gsub("\r\n  ", '')
    response = format_keys response
    confirmation = response[:confirmation][:root]

    if confirmation[:codret] == '0'
      return { success: true }
    else
      return {
          success: false,
          data: {
              error_number: confirmation[:codret],
              error_message: confirmation[:msgret]
          }
      }
    end
  rescue REXML::ParseException
    {
        success: false,
        data: {
            error_message: response_xml.body.gsub("\r\n", '')
        }
    }
  end

  # Calculates the portions of credit card type
  # based on Komerci configuration
  #
  # @param order [Spree::Order]
  #
  # @return [Array]
  #
  def calculate_portions(order)
    amount = order.total.to_f
    ret = []

    portions_number = preferred_max_portion
    minimum_value = preferred_minimum_value.to_f
    tax = preferred_tax_value.to_f

    ret.push({portion: 1, value: amount, total: amount, tax_message: :komerci_without_tax})

    (2..portions_number).each do |number|
      if tax <= 0 or number <= preferred_portion_without_tax
        value = amount / number
        tax_message = :komerci_without_tax
      else
        value = (amount * ((1 + tax / 100) ** number)) / number
        tax_message = :komerci_with_tax
      end

      if value >= minimum_value
        value_total = value * number
        ret.push({portion: number, value: value, total: value_total, tax_message: tax_message})
      end
    end

    ret
  end

  # Calculate the value of the portion based on Komerci configuration
  # (verify if the portion has tax)
  #
  # @param order [Spree::Order]
  # @param portion [Integer]
  #
  # @return [Float]
  #
  def calculate_portion_value(order, portion)
    amount = order.total.to_f
    amount = amount / 100 if amount.is_a? Integer
    tax = preferred_tax_value.to_f

    if tax <= 0 or portion <= preferred_portion_without_tax
      value = amount / portion
    else
      value = (amount * ((1 + tax / 100) ** portion)) / portion
    end
    value
  end

  private

  def format_keys hash
    hash.inject({}) { |result, (key, value)|
      value = format_keys(value) if value.is_a?(Hash)
      result[(key.downcase.to_sym rescue key) || key] = value
      result
    }
  end

end