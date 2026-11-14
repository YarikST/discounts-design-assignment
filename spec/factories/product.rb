# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    sequence(:name) { |number| "Product #{number}" }
    sequence(:sku) { |number| "SKU#{number}" }

    transient do
      with_price { false }
      with_min_recommended_price { false }
    end

    after(:build) do |product, evaluator|
      if evaluator.with_price
        amount = evaluator.with_price.is_a?(TrueClass) ? 1_00 : evaluator.with_price
        product.price = build(:product_price, :final, amount:)
      end

      if evaluator.with_min_recommended_price
        product.min_recommended_price = build(
          :product_price, :min_recommended_price, amount: evaluator.with_min_recommended_price
        )
      end
    end
  end
end
