# frozen_string_literal: true

class CreateOrderOffers < ActiveRecord::Migration[8.1]
  def change
    create_table :order_offers do |t|
      t.references :order, null: false, foreign_key: true
      t.references :order_item, null: false, foreign_key: true, index: false
      t.references :promotion, null: false, polymorphic: true
      t.bigint :discount_amount, null: false
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :order_offers, :order_item_id
    add_index :order_offers, [:order_item_id, :promotion_type, :promotion_id], unique: true,
      where: "discarded_at IS NULL", name: "index_order_offers_on_order_item_and_promotion_kept"
    add_index :order_offers, :discarded_at
  end
end
