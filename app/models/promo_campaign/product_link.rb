# frozen_string_literal: true

class PromoCampaign::ProductLink < ApplicationRecord
  attribute :active, default: true

  belongs_to :promo_campaign
  belongs_to :product

  scope :active, -> { where(active: true) }

  validates :product_id, uniqueness: { scope: :promo_campaign_id }
end
