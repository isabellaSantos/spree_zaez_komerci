module Spree
  CreditCard.class_eval do

    has_one :komerci_transaction, class_name: 'Spree::KomerciTransaction'

  end
end