class AddTotalToSpreeKomerciTransactions < ActiveRecord::Migration
  def change
    add_column :spree_komerci_transactions, :total, :decimal
  end
end
