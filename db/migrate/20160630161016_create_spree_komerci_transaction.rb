class CreateSpreeKomerciTransaction < ActiveRecord::Migration
  def change
    create_table :spree_komerci_transactions do |t|
      t.string :authorization_number
      t.string :order_number
      t.string :authentication_number
      t.string :sequencial_number
      t.string :bin
      t.belongs_to :credit_card

      t.timestamps null: false
    end
  end
end
