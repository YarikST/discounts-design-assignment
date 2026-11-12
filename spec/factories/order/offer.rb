# frozen_string_literal: true

FactoryBot.define do
  factory :order_offer, class: "Order::Offer" do
    discount_amount { 1_00 }
  end
end
