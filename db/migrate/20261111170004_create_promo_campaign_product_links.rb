# frozen_string_literal: true

class CreatePromoCampaignProductLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :promo_campaign_product_links do |t|
      t.references :promo_campaign, null: false, foreign_key: true, index: false
      t.references :product, null: false, foreign_key: true
      t.boolean :active, null: false

      t.timestamps
    end

    add_index :promo_campaign_product_links, [:promo_campaign_id, :product_id], unique: true
  end
end
