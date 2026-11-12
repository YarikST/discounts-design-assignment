# frozen_string_literal: true

class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :customer, foreign_key: true
      t.string :currency, null: false
      t.bigint :subtotal_price, null: false
      t.bigint :discount_amount, null: false
      t.bigint :total_price, null: false

      t.timestamps
    end
  end
end
