# frozen_string_literal: true

class Product < ApplicationRecord
  with_options dependent: :destroy, class_name: "Price", inverse_of: :product do
    has_many :prices
    has_one :price, -> { final }
    has_one :min_recommended_price, -> { min_recommended_price }
  end

  has_many :promo_campaign_product_links, class_name: "PromoCampaign::ProductLink", dependent: :destroy,
    inverse_of: :product

  normalizes :sku, with: -> { it.strip.upcase }

  validates :name, :sku, presence: true
  validates :sku, uniqueness: true
end
