# frozen_string_literal: true

require "rails_helper"

describe PromoCampaign::ItemDiscount do
  let(:item_discount) { described_class.new(promo_campaign:, order_item:) }

  context "when the campaign gives one free item" do
    let(:promo_campaign) { build(:promo_campaign, :one_item_discount, discount_rate: 100, min_items_count: 2) }

    context "when the quantity is below min_items_count" do
      let(:order_item) { build(:order_item, price: 3_11, quantity: 1) }

      it "gives no discount" do
        expect(item_discount).to have_attributes(applicable?: false, discounted_items_count: 0, amount: 0)
      end
    end

    context "when the quantity equals min_items_count" do
      let(:order_item) { build(:order_item, price: 3_11, quantity: 2) }

      it "makes one item free" do
        expect(item_discount).to have_attributes(discounted_items_count: 1, unit_discount_amount: 3_11, amount: 3_11)
      end
    end

    context "when the quantity is above min_items_count" do
      let(:order_item) { build(:order_item, price: 3_11, quantity: 4) }

      it "still makes only one item free" do
        expect(item_discount).to have_attributes(discounted_items_count: 1, amount: 3_11)
      end
    end
  end

  context "when the campaign discounts each item" do
    let(:promo_campaign) { build(:promo_campaign, :each_item_discount, discount_rate: 10, min_items_count: 3) }

    context "when the quantity is below min_items_count" do
      let(:order_item) { build(:order_item, price: 5_00, quantity: 2) }

      it "gives no discount" do
        expect(item_discount).to have_attributes(applicable?: false, discounted_items_count: 0, amount: 0)
      end
    end

    context "when the quantity reaches min_items_count" do
      let(:order_item) { build(:order_item, price: 5_00, quantity: 3) }

      it "discounts every item" do
        expect(item_discount).to have_attributes(discounted_items_count: 3, unit_discount_amount: 50, amount: 1_50)
      end
    end
  end

  context "when the percent of the price is not a whole cent" do
    let(:promo_campaign) { build(:promo_campaign, :each_item_discount, discount_rate: 10, min_items_count: 1) }
    let(:order_item) { build(:order_item, price: 3_11, quantity: 2) }

    it "rounds the unit discount down to a cent" do
      expect(item_discount).to have_attributes(unit_discount_amount: 31, amount: 62)
    end
  end
end
