class AddHotDealsToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :hot_deal, :boolean, default: false, null: false
    add_column :products, :condition_notes, :text
    add_column :products, :compare_at_price, :decimal, precision: 10, scale: 2
    add_column :products, :demo, :boolean, default: false, null: false
    add_index :products, :hot_deal
  end
end
