class AddPaymentIdToSpreeKomerciTransactions < ActiveRecord::Migration
  def change
    add_reference :spree_komerci_transactions, :payment, index: true, foreign_key: true
  end
end
