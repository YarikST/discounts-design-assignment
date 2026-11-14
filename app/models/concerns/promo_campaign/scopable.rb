# frozen_string_literal: true

module PromoCampaign::Scopable
  extend ActiveSupport::Concern

  included do
    scope :enabled, -> { where(enabled: true) }
    scope :ongoing, -> { where(start_at: ..Time.current, finish_at: Time.current..) }
    scope :applicable, -> { enabled.ongoing.completed }
    scope :by_product_ids, lambda { |product_ids|
      where(id: PromoCampaign::ProductLink.active.where(product_id: product_ids).select(:promo_campaign_id))
    }
  end
end
