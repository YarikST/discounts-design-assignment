# frozen_string_literal: true

require "rails_helper"

describe Checkout do
  let(:checkout) { described_class.new(products: skus.map { |sku| products_by_sku.fetch(sku) }) }

  let_it_be(:products_by_sku) do
    {
      "FR" => create(:product, name: "Fruit Tea", sku: "FR", with_price: 3_11),
      "SR" => create(:product, name: "Strawberries", sku: "SR", with_price: 5_00),
      "CF" => create(:product, name: "Coffee", sku: "CF", with_price: 11_23),
      "AJ" => create(:product, name: "Apple Juice", sku: "AJ", with_price: 7_25)
    }
  end

  before do
    create(
      :promo_campaign, :one_item_discount,
      title: "Fruit Tea: buy one, get one free", discount_rate: 100, min_items_count: 2,
      with_products: [products_by_sku.fetch("FR")]
    )
    create(
      :promo_campaign, :each_item_discount,
      title: "Strawberries: 3 or more for $4.50 each", discount_rate: 10, min_items_count: 3,
      with_products: [products_by_sku.fetch("SR")]
    )
  end

  describe "#create_order" do
    context "when items are FR, SR, FR, FR, CF" do
      let(:skus) { %w[FR SR FR FR CF] }

      it "returns an order with total $22.45" do
        expect(checkout.create_order.total_price).to eq(22_45)
      end
    end

    context "when items are FR, FR" do
      let(:skus) { %w[FR FR] }

      it "returns an order with total $3.11" do
        expect(checkout.create_order.total_price).to eq(3_11)
      end
    end

    context "when items are SR, SR, FR, SR" do
      let(:skus) { %w[SR SR FR SR] }

      it "returns an order with total $16.61" do
        expect(checkout.create_order.total_price).to eq(16_61)
      end
    end

    context "when items are FR, FR, FR, FR" do
      let(:skus) { %w[FR FR FR FR] }

      it "gives only one free Fruit Tea per order" do
        expect(checkout.create_order.total_price).to eq(9_33)
      end
    end

    context "when items are AJ, CF" do
      let(:skus) { %w[AJ CF] }

      it "returns an order without discounts" do
        expect(checkout.create_order).to have_attributes(discount_amount: 0, total_price: 18_48)
      end
    end

    context "when there are no products" do
      let(:skus) { [] }

      it "raises an error" do
        expect { checkout.create_order }.to raise_error(Errors::UnprocessableEntity, "Checkout has no products")
      end
    end
  end
end
