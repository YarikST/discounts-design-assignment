# frozen_string_literal: true

require "rails_helper"

describe Order::Item do
  describe "validations" do
    subject { build(:order_item, order: create(:order), product: create(:product)) }

    it { is_expected.to validate_numericality_of(:quantity).only_integer.is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:price).only_integer.is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_uniqueness_of(:product_id).scoped_to(:order_id) }
  end

  describe "#allowed_discount_amount" do
    context "when the item has no min recommended price" do
      let(:order_item) { build(:order_item, price: 5_00, quantity: 3, subtotal_price: 15_00) }

      it "returns the whole subtotal" do
        expect(order_item.allowed_discount_amount).to eq(15_00)
      end
    end

    context "when the item has a min recommended price" do
      let(:order_item) do
        build(:order_item, price: 5_00, quantity: 3, subtotal_price: 15_00, min_recommended_price: 4_80)
      end

      it "keeps the item total at or above the min recommended price" do
        expect(order_item.allowed_discount_amount).to eq(60)
      end
    end

    context "when the min recommended price is above the price" do
      let(:order_item) do
        build(:order_item, price: 5_00, quantity: 1, subtotal_price: 5_00, min_recommended_price: 6_00)
      end

      it "returns zero" do
        expect(order_item.allowed_discount_amount).to eq(0)
      end
    end
  end

  describe "#apply_item_discount" do
    let(:fruit_tea_campaign) { build_stubbed(:promo_campaign) }
    let(:other_campaign) { build_stubbed(:promo_campaign) }
    let(:item_discount) { instance_double(PromoCampaign::ItemDiscount, promo_campaign: fruit_tea_campaign, amount: 3_11) }
    let(:other_item_discount) do
      instance_double(PromoCampaign::ItemDiscount, promo_campaign: other_campaign, amount: 3_11)
    end

    context "when the discount fits into the allowed amount" do
      let(:order_item) { build(:order_item, price: 3_11, quantity: 2, subtotal_price: 6_22) }

      it "keeps the whole discount for the campaign" do
        order_item.apply_item_discount(item_discount)

        expect(order_item.calculated_discounts).to eq(
          fruit_tea_campaign.id => { discount_amount: 3_11, promo_campaign: fruit_tea_campaign }
        )
      end
    end

    context "when the min recommended price limits the discount" do
      let(:order_item) do
        build(:order_item, price: 3_11, quantity: 2, subtotal_price: 6_22, min_recommended_price: 2_50)
      end

      it "applies as much of the discount as possible" do
        order_item.apply_item_discount(item_discount)

        expect(order_item.calculated_discounts).to eq(
          fruit_tea_campaign.id => { discount_amount: 1_22, promo_campaign: fruit_tea_campaign }
        )
      end
    end

    context "when an earlier campaign takes the whole allowed amount" do
      let(:order_item) { build(:order_item, price: 3_11, quantity: 1, subtotal_price: 3_11) }

      it "does not keep a zero discount" do
        order_item.apply_item_discount(item_discount)
        order_item.apply_item_discount(other_item_discount)

        expect(order_item.calculated_discounts).to eq(
          fruit_tea_campaign.id => { discount_amount: 3_11, promo_campaign: fruit_tea_campaign }
        )
      end
    end
  end
end
