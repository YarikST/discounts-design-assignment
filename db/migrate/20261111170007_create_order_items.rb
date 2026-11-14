# frozen_string_literal: true

class CreateOrderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true, index: false
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.string :status, null: false
      t.bigint :price, null: false
      t.bigint :min_recommended_price
      t.bigint :subtotal_price, null: false
      t.bigint :discount_amount, null: false
      t.bigint :total_price, null: false

      t.timestamps
    end

    add_index :order_items, [:order_id, :product_id], unique: true
  end
end
