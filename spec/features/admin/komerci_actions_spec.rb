require 'spec_helper'

describe 'Admin Komerci Payment', { type: :feature, js: true } do

  let(:payment) { create(:komerci_payment, response_code: 'ABC1234') }
  let!(:komerci_transaction) { create(:komerci_transaction, order_number: 'ABC1234', payment: payment) }

  before(:all) { Spree::KomerciConfig[:test_mode] = true }
  before { create_admin_and_sign_in }

  context 'executing the actions' do

    context 'capture the payment' do

      let(:request_url) { Spree::KomerciConfig.conf_authorization_uri }

      it 'should capture the payment' do
        stub_request(:post, request_url).
            with(body: hash_including({ 'filiacao' => Spree::KomerciConfig[:afiliation_key] })).
            to_return(:body => File.read('spec/fixtures/conf_authorize_success.txt'), :status => 200)

        visit spree.admin_order_payments_path payment.order
        find('.action-capture').click

        expect(page).to have_text 'Payment Updated'
        within_row(1) do
          expect(column_text(6)).to eq 'completed'
        end
      end

      it 'should show an error message when try capture and fail' do
        stub_request(:post, request_url).
            with(body: hash_including({ 'filiacao' => Spree::KomerciConfig[:afiliation_key] })).
            to_return(:body => File.read('spec/fixtures/conf_authorize_error.txt'), :status => 200)

        visit spree.admin_order_payments_path payment.order
        find('.action-capture').click

        expect(page).to have_text '98: Cartão inválido'
        within_row(1) do
          expect(column_text(6)).to eq 'failed'
        end
      end
    end

    context 'void the payment' do

      let(:request_url) { Spree::KomerciConfig.void_transaction_uri }

      it 'should void the payment' do
        stub_request(:post, request_url).
            with(body: hash_including({ 'filiacao' => Spree::KomerciConfig[:afiliation_key] })).
            to_return(:body => File.read('spec/fixtures/void_success.txt'), :status => 200)

        visit spree.admin_order_payments_path payment.order
        find('.action-void').click

        expect(page).to have_text 'Payment Updated'
        within_row(1) do
          expect(column_text(6)).to eq 'void'
        end
      end

      it 'should show an error message when try void and fail' do
        stub_request(:post, request_url).
            with(body: hash_including({ 'filiacao' => Spree::KomerciConfig[:afiliation_key] })).
            to_return(:body => File.read('spec/fixtures/void_error.txt'), :status => 200)

        visit spree.admin_order_payments_path payment.order
        find('.action-void').click

        expect(page).to have_text '97: Data de estorno expirou'
        within_row(1) do
          expect(column_text(6)).to eq 'checkout'
        end
      end
    end

  end
end