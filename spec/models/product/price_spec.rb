# frozen_string_literal: true

require "rails_helper"

describe Product::Price do
  describe "validations" do
    subject { build(:product_price, product: create(:product)) }

    it { is_expected.to validate_presence_of(:type) }
    it { is_expected.to validate_uniqueness_of(:type).scoped_to(:product_id) }
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_numericality_of(:amount).only_integer.is_greater_than_or_equal_to(0) }
  end
end
