# frozen_string_literal: true

class CreateProductPrices < ActiveRecord::Migration[8.1]
  def change
    create_table :product_prices do |t|
      t.references :product, null: false, foreign_key: true, index: false
      t.string :type, null: false
      t.bigint :amount, null: false
      t.string :currency, null: false

      t.timestamps
    end

    add_index :product_prices, [:product_id, :type], unique: true
  end
end
