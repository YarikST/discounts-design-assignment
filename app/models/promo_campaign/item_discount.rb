# frozen_string_literal: true

class PromoCampaign::ItemDiscount
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :promo_campaign
  attribute :order_item

  def applicable?
    order_item.quantity >= promo_campaign.min_items_count
  end

  def discounted_items_count
    return 0 unless applicable?

    case promo_campaign.kind
    when PromoCampaign::ONE_ITEM_DISCOUNT then 1
    when PromoCampaign::EACH_ITEM_DISCOUNT then order_item.quantity
    end
  end

  def unit_discount_amount
    order_item.price * promo_campaign.discount_rate / 100
  end

  def amount
    unit_discount_amount * discounted_items_count
  end
end
