# frozen_string_literal: true

class Order::Item < ApplicationRecord
  extend Enumerize
  include Order::Item::Discountable

  STATUSES = [
    ADDED = "added",
    REFUSED_BY_CLIENT = "refused_by_client"
  ].freeze

  enumerize :status, in: STATUSES, default: ADDED, scope: :shallow, predicates: true

  belongs_to :order, inverse_of: :items
  belongs_to :product

  has_many :offers, class_name: "Order::Offer", foreign_key: :order_item_id, dependent: :destroy,
    inverse_of: :order_item, autosave: true

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :price, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :min_recommended_price, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :product_id, uniqueness: { scope: :order_id }

  def calculate_subtotal
    self.subtotal_price = price * quantity
  end

  def calculate_total
    self.discount_amount = offers.reject(&:discarded?).sum(&:discount_amount)
    self.total_price = subtotal_price - discount_amount
  end
end
