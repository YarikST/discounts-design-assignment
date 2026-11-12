# frozen_string_literal: true

class Order::Offer < ApplicationRecord
  include Discard::Model

  belongs_to :order, inverse_of: :offers
  belongs_to :order_item, class_name: "Order::Item", inverse_of: :offers
  belongs_to :promotion, polymorphic: true

  validates :discount_amount, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
