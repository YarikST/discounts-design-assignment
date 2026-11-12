# frozen_string_literal: true

FactoryBot.define do
  factory :order_item, class: "Order::Item" do
    quantity { 1 }
    price { 1_00 }
    subtotal_price { 0 }
    discount_amount { 0 }
    total_price { 0 }
  end
end
