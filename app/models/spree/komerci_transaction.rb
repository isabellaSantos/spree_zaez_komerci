module Spree
  class KomerciTransaction < Base

    belongs_to :credit_card, class_name: 'Spree::CreditCard'
    belongs_to :payment, class_name: 'Spree::Payment'

  end
end