# frozen_string_literal: true

module Order::Item::Discountable
  extend ActiveSupport::Concern

  def calculated_discounts
    @calculated_discounts ||= {}
  end

  def reset_calculated_discounts
    @calculated_discounts = {}
  end

  def allowed_discount_amount
    min_allowed_total_price = min_recommended_price.to_i * quantity

    [subtotal_price - calculated_discounts_amount - min_allowed_total_price, 0].max
  end

  def apply_item_discount(item_discount)
    discount_amount = [item_discount.amount, allowed_discount_amount].min
    return unless discount_amount.positive?

    promo_campaign = item_discount.promo_campaign
    calculated_discounts[promo_campaign.id] = { discount_amount:, promo_campaign: }
  end

  private

  def calculated_discounts_amount
    calculated_discounts.values.sum { it[:discount_amount] }
  end
end
