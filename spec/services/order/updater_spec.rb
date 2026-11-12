# frozen_string_literal: true

require "rails_helper"

describe Order::Updater do
  let(:service) { described_class.new(order:, params:) }

  let_it_be(:fruit_tea) { create(:product, sku: "FR", with_price: 3_11) }
  let_it_be(:strawberries) { create(:product, sku: "SR", with_price: 5_00) }
  let!(:fruit_tea_campaign) do
    create(:promo_campaign, :one_item_discount, discount_rate: 100, min_items_count: 2, with_products: [fruit_tea])
  end
  let!(:strawberries_campaign) do
    create(:promo_campaign, :each_item_discount, discount_rate: 10, min_items_count: 3, with_products: [strawberries])
  end
  let(:created_order) do
    Order::Creator.new(
      params: { items: [{ product_id: fruit_tea.id, quantity: 2 }, { product_id: strawberries.id, quantity: 2 }] }
    ).call
  end
  let(:order) { Order.find(created_order.id) }
  let(:fruit_tea_offer) { created_order.offers.find_by!(promotion: fruit_tea_campaign) }

  describe "#call" do
    context "when an item no longer meets the campaign condition" do
      let(:params) { { items: [{ product_id: fruit_tea.id, quantity: 1 }] } }

      it "discards the offer and recalculates the totals" do
        service.call

        expect(fruit_tea_offer.reload).to have_attributes(discount_amount: 3_11, discarded_at: be_present)
        expect(order.reload).to have_attributes(subtotal_price: 13_11, discount_amount: 0, total_price: 13_11)
      end
    end

    context "when an item reaches the campaign condition" do
      let(:params) { { items: [{ product_id: strawberries.id, quantity: 3 }] } }

      it "adds an offer for the campaign" do
        service.call

        expect(order.reload.offers.kept).to contain_exactly(
          have_attributes(promotion: fruit_tea_campaign, discount_amount: 3_11),
          have_attributes(promotion: strawberries_campaign, discount_amount: 1_50)
        )
        expect(order.total_price).to eq(16_61)
      end
    end

    context "when the client refuses an item" do
      let(:params) { { items: [{ product_id: fruit_tea.id, status: Order::Item::REFUSED_BY_CLIENT }] } }

      it "excludes the item from the totals and discards its offers" do
        service.call

        expect(order.reload.items.find_by!(product: fruit_tea)).to have_attributes(
          status: Order::Item::REFUSED_BY_CLIENT, quantity: 2, discount_amount: 0
        )
        expect(fruit_tea_offer.reload).to have_attributes(discount_amount: 3_11, discarded_at: be_present)
        expect(order).to have_attributes(subtotal_price: 10_00, discount_amount: 0, total_price: 10_00)
      end
    end

    context "when a refused product is added again" do
      let(:order) do
        Order::Updater.new(
          order: Order.find(created_order.id),
          params: { items: [{ product_id: fruit_tea.id, status: Order::Item::REFUSED_BY_CLIENT }] }
        ).call
      end
      let(:params) { { items: [{ product_id: fruit_tea.id, quantity: 3, status: Order::Item::ADDED }] } }

      it "makes the item active with the new quantity and applies the campaign again" do
        service.call

        expect(order.reload.items.find_by!(product: fruit_tea)).to have_attributes(
          status: Order::Item::ADDED, quantity: 3, discount_amount: 3_11
        )
        expect(order.offers.kept).to contain_exactly(
          have_attributes(promotion: fruit_tea_campaign, discount_amount: 3_11)
        )
        expect(order.total_price).to eq(16_22)
      end
    end

    context "when a new product is added" do
      let(:coffee) { create(:product, sku: "CF", with_price: 11_23) }
      let(:params) { { items: [{ product_id: coffee.id, quantity: 1 }] } }

      it "adds the item with a copy of the product price" do
        service.call

        expect(order.reload.items.find_by!(product: coffee)).to have_attributes(quantity: 1, price: 11_23)
        expect(order.total_price).to eq(24_34)
      end
    end
  end
end
