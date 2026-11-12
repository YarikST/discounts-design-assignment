# frozen_string_literal: true

require "rails_helper"

describe Order::Offer do
  describe "validations" do
    it { is_expected.to validate_numericality_of(:discount_amount).only_integer.is_greater_than(0) }
  end
end
