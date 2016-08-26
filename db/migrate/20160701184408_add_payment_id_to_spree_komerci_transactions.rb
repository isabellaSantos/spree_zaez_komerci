class AddPaymentIdToSpreeKomerciTransactions < ActiveRecord::Migration
  def change
    add_column :spree_komerci_transactions, :payment_id, :integer
    add_index :spree_komerci_transactions, :payment_id
  end
end
