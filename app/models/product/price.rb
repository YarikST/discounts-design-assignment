# frozen_string_literal: true

class Product::Price < ApplicationRecord
  extend Enumerize

  self.inheritance_column = :_type_disabled

  TYPES = [
    FINAL = "final",
    MIN_RECOMMENDED_PRICE = "min_recommended_price"
  ].freeze

  enumerize :type, in: TYPES, scope: :shallow, predicates: true
  enumerize :currency, in: Constants::CURRENCIES, default: Constants::USD

  belongs_to :product

  validates :type, presence: true, uniqueness: { scope: :product_id }
  validates :amount, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
