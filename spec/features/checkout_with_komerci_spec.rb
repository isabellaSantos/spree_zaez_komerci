require 'spec_helper'

describe 'Checkout with Komerci Payment Method', { type: :feature, js: true } do

  include_context 'checkout setup'
  let!(:payment_method) { create(:komerci_payment_method, id: 1) }

  before { Spree::KomerciConfig[:test_mode] = true }

  it 'should create an valid Komerci payment' do
    mock_komerci_request 'spec/fixtures/authorize_success.txt'
    navigate_to_payment
    fill_credit_card_data

    expect(page).to have_text 'Your order has been processed successfully'
    expect(page).to have_text 'Ending in 1111'

    expect(Spree::Order.complete.count).to eq 1
  end

  it 'should show an error message when the response of Komerci is unauthorized' do
    mock_komerci_request 'spec/fixtures/authorize_error.txt'
    navigate_to_payment
    fill_credit_card_data

    expect(page).to have_text '99: Credenciais invalidas'
    expect(Spree::Order.first.payments.last.state).to eq 'failed'
  end

  def navigate_to_payment
    # add mug to cart
    visit spree.root_path
    click_link mug.name
    click_button 'add-to-cart-button'
    click_button 'Checkout'

    fill_in 'spree_user_email', with: 'test@example.com'
    fill_in 'spree_user_password', with: 'spree123'
    fill_in 'spree_user_password_confirmation', with: 'spree123'
    click_on 'Create'

    # set address
    address = 'order_bill_address_attributes'
    fill_in "#{address}_firstname", with: 'Ryan'
    fill_in "#{address}_lastname", with: 'Bigg'
    fill_in "#{address}_address1", with: '143 Swan Street'
    fill_in "#{address}_city", with: 'Richmond'
    select 'United States of America', from: "#{address}_country_id"
    select 'Alabama', from: "#{address}_state_id"
    fill_in "#{address}_zipcode", with: '12345'
    fill_in "#{address}_phone", with: '(555) 555-5555'
    # confirm address
    click_button 'Save and Continue'

    # confirm shipping method
    click_button 'Save and Continue'
  end

  def fill_credit_card_data
    fill_in 'Name on card', with: 'Spree Commerce'
    # set the fields with javascript
    page.execute_script "$('#cielo_card_number').val('4111111111111111');"
    page.execute_script "$('#card_expiry').val('04 / 20');"
    fill_in 'Card Code', with: '123'
    # confirm payment method
    click_button 'Save and Continue'
  end

  def mock_komerci_request(filename)
    stub_request(:post, Spree::KomerciConfig.authorize_uri).
        with(body: hash_including({ 'filiacao' => Spree::KomerciConfig[:afiliation_key] })).
        to_return(:body => File.read(filename), :status => 200)
  end

end