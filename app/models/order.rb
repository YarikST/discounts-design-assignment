# frozen_string_literal: true

class Order < ApplicationRecord
  extend Enumerize

  enumerize :currency, in: Constants::CURRENCIES, default: Constants::USD

  belongs_to :customer, optional: true

  has_many :items, class_name: "Order::Item", dependent: :destroy, inverse_of: :order, autosave: true
  has_many :offers, class_name: "Order::Offer", dependent: :destroy, inverse_of: :order

  validates :subtotal_price, :discount_amount, :total_price,
    presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def active_items
    items.reject(&:refused_by_client?)
  end

  def calculate_subtotals
    items.each(&:calculate_subtotal)
    self.subtotal_price = active_items.sum(&:subtotal_price)
  end

  def calculate_totals
    items.each(&:calculate_total)
    self.discount_amount = active_items.sum(&:discount_amount)
    self.total_price = subtotal_price - discount_amount
  end
end
