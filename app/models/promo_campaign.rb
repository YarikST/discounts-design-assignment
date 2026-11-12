# frozen_string_literal: true

class PromoCampaign < ApplicationRecord
  extend Enumerize
  include PromoCampaign::Scopable

  KINDS = [
    ONE_ITEM_DISCOUNT = "one_item_discount",
    EACH_ITEM_DISCOUNT = "each_item_discount"
  ].freeze

  STATUSES = [
    PENDING = "pending",
    IN_PROGRESS = "in_progress",
    COMPLETED = "completed",
    FAILED = "failed"
  ].freeze

  IMMUTABLE_ATTRIBUTES = %w[kind discount_rate min_items_count start_at].freeze

  attribute :enabled, default: true

  enumerize :kind, in: KINDS, scope: :shallow, predicates: true
  enumerize :status, in: STATUSES, default: PENDING, scope: :shallow, predicates: true

  has_many :product_links, class_name: "PromoCampaign::ProductLink", dependent: :destroy, inverse_of: :promo_campaign
  has_many :products, through: :product_links
  has_many :order_offers, class_name: "Order::Offer", as: :promotion, dependent: :restrict_with_exception,
    inverse_of: :promotion

  validates :title, :kind, :status, :start_at, :finish_at, presence: true
  validates :discount_rate, presence: true, numericality: { only_integer: true, in: 1..100 }
  validates :min_items_count, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :finish_at, comparison: { greater_than: :start_at }, if: -> { start_at && finish_at }
  validate :terms_unchanged_after_start, on: :update

  def item_discount_for(order_item)
    PromoCampaign::ItemDiscount.new(promo_campaign: self, order_item:)
  end

  private

  # The saved start_at decides, so moving start_at to the future cannot unlock the terms
  def terms_unchanged_after_start
    return unless start_at_in_database.past?

    IMMUTABLE_ATTRIBUTES.select { attribute_changed?(it) }.each { errors.add(it, :immutable_after_start) }
  end
end
