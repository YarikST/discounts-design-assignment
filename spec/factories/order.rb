# frozen_string_literal: true

FactoryBot.define do
  factory :order do
    currency { Constants::USD }
    subtotal_price { 0 }
    discount_amount { 0 }
    total_price { 0 }

    transient do
      with_items { [] }
    end

    after(:build) do |order, evaluator|
      evaluator.with_items.each do |item_attributes|
        order.items << build(:order_item, **item_attributes)
      end
    end
  end
end
