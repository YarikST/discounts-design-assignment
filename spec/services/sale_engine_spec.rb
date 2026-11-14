# frozen_string_literal: true

require "rails_helper"

describe SaleEngine do
  let(:service) { described_class.new(order:) }

  let_it_be(:fruit_tea) { create(:product, sku: "FR", with_price: 3_11) }
  let_it_be(:strawberries) { create(:product, sku: "SR", with_price: 5_00) }
  let_it_be(:coffee) { create(:product, sku: "CF", with_price: 11_23) }

  context "when the order is new" do
    let!(:fruit_tea_campaign) do
      create(:promo_campaign, :one_item_discount, discount_rate: 100, min_items_count: 2, with_products: [fruit_tea])
    end
    let!(:strawberries_campaign) do
      create(:promo_campaign, :each_item_discount, discount_rate: 10, min_items_count: 3, with_products: [strawberries])
    end
    let(:order) do
      build(
        :order,
        with_items: [
          { product: fruit_tea, price: 3_11, quantity: 3 },
          { product: strawberries, price: 5_00, quantity: 3 },
          { product: coffee, price: 11_23, quantity: 1 }
        ]
      )
    end

    it "applies every campaign to its items and calculates the totals" do
      service.call

      expect(order).to have_attributes(subtotal_price: 35_56, discount_amount: 4_61, total_price: 30_95)
      expect(order.items.map { [it.product, it.discount_amount, it.total_price] }).to eq(
        [[fruit_tea, 3_11, 6_22], [strawberries, 1_50, 13_50], [coffee, 0, 11_23]]
      )
      expect(order.items.flat_map(&:offers).map { [it.promotion, it.discount_amount] }).to eq(
        [[fruit_tea_campaign, 3_11], [strawberries_campaign, 1_50]]
      )
    end
  end

  context "when two campaigns apply to one product" do
    let!(:free_item_campaign) do
      create(:promo_campaign, :one_item_discount, discount_rate: 100, min_items_count: 2, with_products: [fruit_tea])
    end
    let!(:each_item_campaign) do
      create(:promo_campaign, :each_item_discount, discount_rate: 10, min_items_count: 1, with_products: [fruit_tea])
    end

    context "when the product has no min recommended price" do
      let(:order) { build(:order, with_items: [{ product: fruit_tea, price: 3_11, quantity: 2 }]) }

      it "applies the campaigns one by one in id order" do
        service.call

        expect(order.items.first.offers.map { [it.promotion, it.discount_amount] }).to eq(
          [[free_item_campaign, 3_11], [each_item_campaign, 62]]
        )
        expect(order.total_price).to eq(2_49)
      end
    end

    context "when the min recommended price limits the discount" do
      let(:order) do
        build(:order, with_items: [{ product: fruit_tea, price: 3_11, min_recommended_price: 2_00, quantity: 2 }])
      end

      it "applies as much as the min recommended price allows" do
        service.call

        expect(order.items.first.offers.map { [it.promotion, it.discount_amount] }).to eq(
          [[free_item_campaign, 2_22]]
        )
        expect(order.total_price).to eq(4_00)
      end
    end
  end

  context "when the campaign link to the product is not active" do
    let(:promo_campaign) { create(:promo_campaign, :one_item_discount, discount_rate: 100, min_items_count: 2) }
    let(:order) { build(:order, with_items: [{ product: fruit_tea, price: 3_11, quantity: 2 }]) }

    before { create(:promo_campaign_product_link, :inactive, promo_campaign:, product: fruit_tea) }

    it "does not apply the campaign" do
      service.call

      expect(order).to have_attributes(discount_amount: 0, total_price: 6_22)
      expect(order.items.first.offers).to be_empty
    end
  end

  context "when the order already has offers" do
    let(:persisted_order) { create(:order) }
    let(:order) { Order.find(persisted_order.id) }
    let(:order_item) do
      create(:order_item, order: persisted_order, product: fruit_tea, price: 3_11, quantity: fruit_tea_quantity)
    end
    let!(:offer) do
      create(:order_offer, order: persisted_order, order_item:, promotion: promo_campaign, discount_amount: 3_11)
    end
    let(:fruit_tea_quantity) { 2 }

    context "when the item was refused by the client" do
      let(:order_item) do
        create(
          :order_item,
          order: persisted_order, product: fruit_tea, price: 3_11, quantity: 2, status: Order::Item::REFUSED_BY_CLIENT
        )
      end
      let(:promo_campaign) do
        create(:promo_campaign, :one_item_discount, discount_rate: 100, min_items_count: 2, with_products: [fruit_tea])
      end

      it "discards the offer and leaves the item out of the order totals" do
        service.call

        expect(order.items.first.offers).to contain_exactly(have_attributes(id: offer.id, discarded_at: be_present))
        expect(order.items.first.discount_amount).to eq(0)
        expect(order).to have_attributes(subtotal_price: 0, discount_amount: 0, total_price: 0)
      end
    end

    context "when the campaign ended after checkout" do
      let(:promo_campaign) do
        create(
          :promo_campaign, :one_item_discount, :finished,
          discount_rate: 100, min_items_count: 2, with_products: [fruit_tea]
        )
      end

      it "keeps the discount" do
        service.call

        expect(order.items.first.offers).to contain_exactly(have_attributes(id: offer.id, discarded_at: nil))
        expect(order.total_price).to eq(3_11)
      end
    end

    context "when the campaign was disabled after checkout" do
      let(:promo_campaign) do
        create(
          :promo_campaign, :one_item_discount, :disabled,
          discount_rate: 100, min_items_count: 2, with_products: [fruit_tea]
        )
      end

      it "keeps the discount" do
        service.call

        expect(order.items.first.offers).to contain_exactly(have_attributes(id: offer.id, discarded_at: nil))
        expect(order.total_price).to eq(3_11)
      end
    end

    context "when the campaign link to the product was deactivated after checkout" do
      let(:promo_campaign) { create(:promo_campaign, :one_item_discount, discount_rate: 100, min_items_count: 2) }

      before { create(:promo_campaign_product_link, :inactive, promo_campaign:, product: fruit_tea) }

      it "keeps the discount" do
        service.call

        expect(order.items.first.offers).to contain_exactly(have_attributes(id: offer.id, discarded_at: nil))
        expect(order.total_price).to eq(3_11)
      end
    end

    context "when the campaign has no product links after checkout" do
      let(:promo_campaign) { create(:promo_campaign, :one_item_discount, discount_rate: 100, min_items_count: 2) }

      it "keeps the discount" do
        service.call

        expect(order.items.first.offers).to contain_exactly(have_attributes(id: offer.id, discarded_at: nil))
        expect(order.total_price).to eq(3_11)
      end
    end

    context "when the campaign gives another amount now" do
      let(:promo_campaign) do
        create(:promo_campaign, :each_item_discount, discount_rate: 10, min_items_count: 1, with_products: [fruit_tea])
      end

      it "updates the amount of the same offer" do
        service.call

        expect(order.items.first.offers).to contain_exactly(
          have_attributes(id: offer.id, discount_amount: 62, discarded_at: nil)
        )
        expect(order.total_price).to eq(5_60)
      end
    end

    context "when the item no longer meets the campaign condition" do
      let(:fruit_tea_quantity) { 1 }
      let(:promo_campaign) do
        create(:promo_campaign, :one_item_discount, discount_rate: 100, min_items_count: 2, with_products: [fruit_tea])
      end

      it "discards the offer" do
        service.call

        expect(order.items.first.offers).to contain_exactly(have_attributes(id: offer.id, discarded_at: be_present))
        expect(order.total_price).to eq(3_11)
      end
    end
  end
end
