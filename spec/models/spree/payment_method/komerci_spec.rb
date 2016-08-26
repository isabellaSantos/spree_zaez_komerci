require 'spec_helper'

describe Spree::PaymentMethod::Komerci do

  let(:komerci) { FactoryGirl.build(:komerci_payment_method) }
  let(:credit_card) { FactoryGirl.build(:credit_card_komerci) }
  let!(:payment) { create(:komerci_payment, source: credit_card) }
  let(:order) { create(:order) }
  let(:gateway_options) { {order_id: "#{order.number}-#{payment.number}", portions: 2} }

  before do
    payment
    Spree::KomerciConfig[:test_mode] = true
    Spree::KomerciConfig[:afiliation_key] = 'ABC1234'
  end

  after(:all) do
    Spree::KomerciConfig[:test_mode] = false
    Spree::KomerciConfig[:afiliation_key] = ''
  end

  context 'authorize' do

    let(:request_url) { Spree::KomerciConfig.authorize_uri }

    it 'should authorize the payment' do
      mock_komerci_request request_url, 'spec/fixtures/authorize_success.txt'

      response = komerci.authorize(1000, credit_card, gateway_options)
      expect(response.success?).to be_truthy
      expect(response.message).to eq 'Komerci: transaction authorized successfully'

      komerci_transaction = Spree::KomerciTransaction.find_by order_number: 'NCV1234'
      expect(komerci_transaction.authorization_number).to eq 'NA1234'
      expect(komerci_transaction.authentication_number).to eq 'NAU1234'
      expect(komerci_transaction.sequencial_number).to eq '123'
      expect(komerci_transaction.bin).to eq 'BRL'
    end

    context 'error' do

      it 'should return an error when the payment do not have any portions' do
        gateway_options = { order_id: "#{order.number}-#{payment.number}" }

        response = komerci.authorize(1000, credit_card, gateway_options)
        expect(response.success?).to be_falsey
        expect(response.message).to eq 'Komerci: The number of portions is required'
      end

      it 'should return an error when the request to Komerci is invalid' do
        mock_komerci_request request_url, 'spec/fixtures/error.txt'

        response = komerci.authorize(1000, credit_card, gateway_options)
        expect(response.success?).to be_falsey
        expect(response.message).to eq 'Missing parameter: Total.'
      end

      it 'should return an error when the request to Komerci is unauthorized' do
        mock_komerci_request request_url, 'spec/fixtures/authorize_error.txt'

        response = komerci.authorize(1000, credit_card, gateway_options)
        expect(response.success?).to be_falsey
        expect(response.message).to eq '99: Credenciais invalidas'
      end

    end

  end

  context 'purchase' do

    let(:request_url) { Spree::KomerciConfig.authorize_uri }

    it 'should purchase the payment' do
      mock_komerci_request request_url, 'spec/fixtures/authorize_success.txt'

      response = komerci.purchase(1500, credit_card, gateway_options)
      expect(response.success?).to be_truthy
      expect(response.message).to eq 'Komerci: transaction purchased successfully'

      komerci_transaction = Spree::KomerciTransaction.find_by order_number: 'NCV1234'
      expect(komerci_transaction.authorization_number).to eq 'NA1234'
      expect(komerci_transaction.authentication_number).to eq 'NAU1234'
      expect(komerci_transaction.sequencial_number).to eq '123'
      expect(komerci_transaction.bin).to eq 'BRL'
    end

    context 'error' do

      it 'should return an error when the payment do not have any portions' do
        gateway_options = { order_id: "#{order.number}-#{payment.number}" }

        response = komerci.purchase(1500, credit_card, gateway_options)
        expect(response.success?).to be_falsey
        expect(response.message).to eq 'Komerci: The number of portions is required'
      end

      it 'should return an error when the request to Komerci is invalid' do
        mock_komerci_request request_url, 'spec/fixtures/error.txt'

        response = komerci.purchase(1500, credit_card, gateway_options)
        expect(response.success?).to be_falsey
        expect(response.message).to eq 'Missing parameter: Total.'
      end

      it 'should return an error when the request to Komerci is unauthorized' do
        mock_komerci_request request_url, 'spec/fixtures/authorize_error.txt'

        response = komerci.purchase(1500, credit_card, gateway_options)
        expect(response.success?).to be_falsey
        expect(response.message).to eq '99: Credenciais invalidas'
      end

    end

  end

  context 'capture' do

    let(:request_url) { Spree::KomerciConfig.conf_authorization_uri }
    let!(:komerci_transaction) { create(:komerci_transaction, order_number: 'NCV1234') }

    it 'should capture the payment' do
      mock_komerci_request request_url, 'spec/fixtures/conf_authorize_success.txt'

      response = komerci.capture(1900, 'NCV1234', {})
      expect(response.success?).to be_truthy
      expect(response.message).to eq 'Komerci: captured successfully'
    end

    context 'error' do

      it 'should return an error when the request to Komerci is invalid' do
        mock_komerci_request request_url, 'spec/fixtures/error.txt'

        response = komerci.capture(1900, 'NCV1234', {})
        expect(response.success?).to be_falsey
        expect(response.message).to eq 'Missing parameter: Total.'
      end

      it 'should return an error when the request to Komerci is unauthorized' do
        mock_komerci_request request_url, 'spec/fixtures/conf_authorize_error.txt'

        response = komerci.capture(1900, 'NCV1234', {})
        expect(response.success?).to be_falsey
        expect(response.message).to eq '98: Cartão inválido'
      end

    end
  end

  context 'void' do

    let(:request_url) { Spree::KomerciConfig.void_transaction_uri }
    let!(:komerci_transaction) { create(:komerci_transaction, order_number: 'NCV1234') }

    it 'should void the payment' do
      mock_komerci_request request_url, 'spec/fixtures/void_success.txt'

      response = komerci.void('NCV1234', {})
      expect(response.success?).to be_truthy
      expect(response.message).to eq 'Komerci: Voided successfully'
    end

    context 'error' do

      it 'should return an error when the request to Komerci is invalid' do
        mock_komerci_request request_url, 'spec/fixtures/error.txt'

        response = komerci.void('NCV1234', {})
        expect(response.success?).to be_falsey
        expect(response.message).to eq 'Missing parameter: Total.'
      end

      it 'should return an error when the request to Komerci is unauthorized' do
        mock_komerci_request request_url, 'spec/fixtures/void_error.txt'

        response = komerci.void('NCV1234', {})
        expect(response.success?).to be_falsey
        expect(response.message).to eq '97: Data de estorno expirou'
      end
    end

  end

  context 'cancel' do

    let(:request_url) { Spree::KomerciConfig.void_transaction_uri }
    let!(:komerci_transaction) { create(:komerci_transaction, order_number: 'NCV1234') }

    it 'should cancel the payment' do
      mock_komerci_request request_url, 'spec/fixtures/void_success.txt'

      response = komerci.cancel('NCV1234')
      expect(response.success?).to be_truthy
      expect(response.message).to eq 'Komerci: Canceled successfully'
    end

  end

  def mock_komerci_request(url, filename)
    stub_request(:post, url).
        with(body: hash_including({ 'filiacao' => Spree::KomerciConfig[:afiliation_key] })).
        to_return(:body => File.read(filename), :status => 200)
  end
end