# frozen_string_literal: true

require "rails_helper"

describe SaleEngine::PromoCampaignApplier do
  let(:service) { described_class.new(order:, promo_campaign:) }

  let_it_be(:fruit_tea) { create(:product) }
  let_it_be(:coffee) { create(:product) }
  let_it_be(:apple_juice) { create(:product) }
  let(:promo_campaign) do
    create(:promo_campaign, :each_item_discount, discount_rate: 10, min_items_count: 1, with_products: [fruit_tea])
  end
  let(:coffee_offers) { [] }
  let(:order) do
    build(
      :order,
      with_items: [
        { product: fruit_tea, price: 3_00, quantity: 1, subtotal_price: 3_00 },
        { product: coffee, price: 11_00, quantity: 1, subtotal_price: 11_00, offers: coffee_offers },
        { product: apple_juice, price: 7_00, quantity: 1, subtotal_price: 7_00 }
      ]
    )
  end

  before { create(:promo_campaign_product_link, :inactive, promo_campaign:, product: coffee) }

  describe "#call" do
    context "when no item has an offer of the campaign" do
      it "calculates the discount only for items with an active link to the campaign" do
        service.call

        expect(order.items.map(&:calculated_discounts)).to eq(
          [{ promo_campaign.id => { discount_amount: 30, promo_campaign: } }, {}, {}]
        )
      end
    end

    context "when an item without an active link already has an offer of the campaign" do
      let(:coffee_offers) { [build(:order_offer, promotion: promo_campaign)] }

      it "calculates the discount for that item too" do
        service.call

        expect(order.items.map(&:calculated_discounts)).to eq(
          [
            { promo_campaign.id => { discount_amount: 30, promo_campaign: } },
            { promo_campaign.id => { discount_amount: 1_10, promo_campaign: } },
            {}
          ]
        )
      end
    end

    context "when an item without an active link has a discarded offer of the campaign" do
      let(:coffee_offers) { [build(:order_offer, promotion: promo_campaign, discarded_at: 1.hour.ago)] }

      it "does not calculate the discount for that item" do
        service.call

        expect(order.items.map(&:calculated_discounts)).to eq(
          [{ promo_campaign.id => { discount_amount: 30, promo_campaign: } }, {}, {}]
        )
      end
    end
  end
end
