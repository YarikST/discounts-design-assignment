# frozen_string_literal: true

FactoryBot.define do
  factory :promo_campaign_product_link, class: "PromoCampaign::ProductLink" do
    active { true }

    trait :inactive do
      active { false }
    end
  end
end
