# frozen_string_literal: true

class SaleEngine < BaseService
  option :order

  def call
    order.calculate_subtotals
    calculate_promo_campaigns_discount
    order.calculate_totals
  end

  private

  def calculate_promo_campaigns_discount
    order.items.each(&:reset_calculated_discounts)

    promo_campaigns.each do |promo_campaign|
      SaleEngine::PromoCampaignApplier.new(order:, promo_campaign:).call
    end

    assign_promo_campaign_offers
  end

  def assign_promo_campaign_offers
    order.items.each do |order_item|
      item_offers = kept_promo_campaign_offers(order_item)

      item_offers.each do |offer|
        offer.discarded_at = Time.current unless order_item.calculated_discounts.key?(offer.promotion_id)
      end

      order_item.calculated_discounts.each do |promo_campaign_id, calculated_discount|
        offer = item_offers.find { it.promotion_id == promo_campaign_id }
        offer ||= order_item.offers.build(order:, promotion: calculated_discount[:promo_campaign])
        offer.discount_amount = calculated_discount[:discount_amount]
      end
    end
  end

  def promo_campaigns
    applicable_promo_campaigns.or(applied_promo_campaigns)
      .sort_by { [applied_promo_campaign_ids.include?(it.id) ? 0 : 1, it.id] }
  end

  def applicable_promo_campaigns
    PromoCampaign.applicable.by_product_ids(product_ids)
  end

  def applied_promo_campaigns
    PromoCampaign.where(id: applied_promo_campaign_ids)
  end

  memo_wise def active_items
    order.active_items
  end

  memo_wise def product_ids
    active_items.map(&:product_id)
  end

  memo_wise def applied_promo_campaign_ids
    active_items.flat_map { kept_promo_campaign_offers(it) }.map(&:promotion_id)
  end

  def kept_promo_campaign_offers(order_item)
    order_item.offers.select { !it.discarded? && it.promotion_type == PromoCampaign.name }
  end
end
