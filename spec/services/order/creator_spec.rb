# frozen_string_literal: true

require "rails_helper"

describe Order::Creator do
  let(:service) { described_class.new(params:) }

  let_it_be(:fruit_tea) { create(:product, sku: "FR", with_price: 3_11) }
  let_it_be(:whisky) { create(:product, sku: "WH", with_price: 30_00, with_min_recommended_price: 28_00) }
  let_it_be(:customer) { create(:customer) }
  let!(:fruit_tea_campaign) do
    create(:promo_campaign, :one_item_discount, discount_rate: 100, min_items_count: 2, with_products: [fruit_tea])
  end

  describe "#call" do
    context "when every product has a final price" do
      let(:params) do
        { customer:, items: [{ product_id: fruit_tea.id, quantity: 3 }, { product_id: whisky.id, quantity: 1 }] }
      end

      it "saves the order with items, offers and totals" do
        order = service.call.reload

        expect(order).to have_attributes(
          customer:, subtotal_price: 39_33, discount_amount: 3_11, total_price: 36_22, persisted?: true
        )
        expect(order.items).to contain_exactly(
          have_attributes(product: fruit_tea, quantity: 3, price: 3_11, min_recommended_price: nil, total_price: 6_22),
          have_attributes(product: whisky, quantity: 1, price: 30_00, min_recommended_price: 28_00, total_price: 30_00)
        )
        expect(order.offers).to contain_exactly(
          have_attributes(promotion: fruit_tea_campaign, discount_amount: 3_11,
            order_item: order.items.find_by!(product: fruit_tea))
        )
      end
    end

    context "when a product has no final price" do
      let(:product_without_price) { create(:product, sku: "NP") }
      let(:params) { { items: [{ product_id: product_without_price.id, quantity: 1 }] } }

      it "raises an error" do
        expect { service.call }.to raise_error(Errors::UnprocessableEntity, "Product NP has no final price")
        expect(Order.count).to eq(0)
      end
    end

    context "when a product does not exist" do
      let(:params) { { items: [{ product_id: 0, quantity: 1 }] } }

      it "raises an error" do
        expect { service.call }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
