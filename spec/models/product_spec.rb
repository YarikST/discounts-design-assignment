# frozen_string_literal: true

require "rails_helper"

describe Product do
  describe "validations" do
    subject { build(:product) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:sku) }
    it { is_expected.to validate_uniqueness_of(:sku).ignoring_case_sensitivity }
  end

  describe "#sku" do
    let(:product) { build(:product, sku: " fr ") }

    it "strips and upcases the value" do
      expect(product.sku).to eq("FR")
    end
  end

  describe "#price" do
    let(:product) { create(:product, with_price: 3_11, with_min_recommended_price: 2_00) }

    it "returns the final price" do
      expect(product.reload.price).to have_attributes(type: Product::Price::FINAL, amount: 3_11)
    end
  end

  describe "#min_recommended_price" do
    let(:product) { create(:product, with_price: 3_11, with_min_recommended_price: 2_00) }

    it "returns the min recommended price" do
      expect(product.reload.min_recommended_price)
        .to have_attributes(type: Product::Price::MIN_RECOMMENDED_PRICE, amount: 2_00)
    end
  end
end
