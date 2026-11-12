# frozen_string_literal: true

require "rails_helper"

describe PromoCampaign::ProductLink do
  describe "validations" do
    subject { create(:promo_campaign_product_link, promo_campaign: create(:promo_campaign), product: create(:product)) }

    it { is_expected.to validate_uniqueness_of(:product_id).scoped_to(:promo_campaign_id) }
  end
end
