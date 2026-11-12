# frozen_string_literal: true

FactoryBot.define do
  factory :promo_campaign do
    sequence(:title) { |number| "Promo campaign #{number}" }
    kind { PromoCampaign::ONE_ITEM_DISCOUNT }
    discount_rate { 100 }
    min_items_count { 2 }
    enabled { true }
    status { PromoCampaign::COMPLETED }
    start_at { 1.day.ago }
    finish_at { 1.month.from_now }

    transient do
      with_products { [] }
    end

    trait :one_item_discount do
      kind { PromoCampaign::ONE_ITEM_DISCOUNT }
    end

    trait :each_item_discount do
      kind { PromoCampaign::EACH_ITEM_DISCOUNT }
    end

    trait :disabled do
      enabled { false }
    end

    trait :pending do
      status { PromoCampaign::PENDING }
    end

    trait :finished do
      start_at { 1.month.ago }
      finish_at { 1.day.ago }
    end

    trait :not_started do
      start_at { 1.day.from_now }
      finish_at { 1.month.from_now }
    end

    after(:build) do |promo_campaign, evaluator|
      evaluator.with_products.each do |product|
        promo_campaign.product_links << build(:promo_campaign_product_link, product:)
      end
    end
  end
end
