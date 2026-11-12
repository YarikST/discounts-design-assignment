# frozen_string_literal: true

class SaleEngine::PromoCampaignApplier < BaseService
  option :order
  option :promo_campaign

  def call
    linked_order_items.each do |order_item|
      order_item.apply_item_discount(promo_campaign.item_discount_for(order_item))
    end
  end

  private

  def linked_order_items
    active_items.select { linked_product_ids.include?(it.product_id) || applied_order_item?(it) }
  end

  def applied_order_item?(order_item)
    order_item.offers.any? do |offer|
      !offer.discarded? && offer.promotion_type == PromoCampaign.name && offer.promotion_id == promo_campaign.id
    end
  end

  memo_wise def active_items
    order.active_items
  end

  memo_wise def linked_product_ids
    promo_campaign.product_links.active
      .where(product_id: active_items.map(&:product_id))
      .pluck(:product_id)
      .to_set
  end
end
