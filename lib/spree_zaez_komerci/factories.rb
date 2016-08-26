FactoryGirl.define do
  factory :komerci_payment_method, class: Spree::PaymentMethod::Komerci do
    name 'Komerci'
    created_at Date.today
  end

  factory :komerci_payment, class: Spree::Payment do
    amount 15.00
    order
    state 'checkout'
    portions 2
    association(:payment_method, factory: :komerci_payment_method)
    association(:source, factory: :credit_card_komerci)
  end

  factory :credit_card_komerci, class: Spree::CreditCard do
    verification_value 123
    month 12
    year { 1.year.from_now.year }
    number '4111111111111111'
    name 'Spree Commerce'
    cc_type 'visa'
    association(:payment_method, factory: :komerci_payment_method)
  end

  factory :komerci_transaction, class: Spree::KomerciTransaction do
    association(:credit_card, factory: :credit_card_komerci)
    association(:payment, factory: :komerci_payment)
  end
end
