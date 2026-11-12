# frozen_string_literal: true

class CreatePromoCampaigns < ActiveRecord::Migration[8.1]
  def change
    create_table :promo_campaigns do |t|
      t.string :title, null: false
      t.string :kind, null: false
      t.integer :discount_rate, null: false
      t.integer :min_items_count, null: false
      t.boolean :enabled, null: false
      t.string :status, null: false
      t.datetime :start_at, null: false
      t.datetime :finish_at, null: false

      t.timestamps
    end

    add_index :promo_campaigns, [:start_at, :finish_at]
    add_index :promo_campaigns, :enabled
    add_index :promo_campaigns, :status
  end
end
