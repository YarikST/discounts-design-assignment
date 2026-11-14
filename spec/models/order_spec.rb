# frozen_string_literal: true

require "rails_helper"

describe Order do
  describe "#calculate_subtotals" do
    let(:order) do
      build(
        :order,
        with_items: [
          { product: build(:product), price: 3_11, quantity: 3 },
          { product: build(:product), price: 5_00, quantity: 1 },
          { product: build(:product), price: 7_25, quantity: 1, status: Order::Item::REFUSED_BY_CLIENT }
        ]
      )
    end

    it "sets the item subtotals and sums only the active items into the order subtotal" do
      order.calculate_subtotals

      expect(order.items.map(&:subtotal_price)).to eq([9_33, 5_00, 7_25])
      expect(order.subtotal_price).to eq(14_33)
    end
  end

  describe "#calculate_totals" do
    let(:order) do
      build(
        :order,
        subtotal_price: 14_33,
        with_items: [
          {
            product: build(:product),
            price: 3_11,
            quantity: 3,
            subtotal_price: 9_33,
            offers: [
              build(:order_offer, discount_amount: 3_11),
              build(:order_offer, discount_amount: 1_00, discarded_at: 1.hour.ago)
            ]
          },
          { product: build(:product), price: 5_00, quantity: 1, subtotal_price: 5_00 },
          {
            product: build(:product),
            price: 7_25,
            quantity: 1,
            subtotal_price: 7_25,
            status: Order::Item::REFUSED_BY_CLIENT
          }
        ]
      )
    end

    it "takes the item discounts from the kept offers and sums only the active items into the order" do
      order.calculate_totals

      expect(order.items.map { [it.discount_amount, it.total_price] }).to eq([[3_11, 6_22], [0, 5_00], [0, 7_25]])
      expect(order).to have_attributes(discount_amount: 3_11, total_price: 11_22)
    end
  end

  describe "#active_items" do
    let(:active_item) { build(:order_item, product: build(:product)) }
    let(:refused_item) { build(:order_item, product: build(:product), status: Order::Item::REFUSED_BY_CLIENT) }
    let(:order) { build(:order).tap { |order_with_items| order_with_items.items = [active_item, refused_item] } }

    it "skips the items refused by the client" do
      expect(order.active_items).to eq([active_item])
    end
  end
end
