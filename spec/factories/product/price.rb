# frozen_string_literal: true

FactoryBot.define do
  factory :product_price, class: "Product::Price" do
    type { Product::Price::FINAL }
    amount { 1_00 }
    currency { Constants::USD }

    trait :final do
      type { Product::Price::FINAL }
    end

    trait :min_recommended_price do
      type { Product::Price::MIN_RECOMMENDED_PRICE }
    end
  end
end
