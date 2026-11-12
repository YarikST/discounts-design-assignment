# frozen_string_literal: true

require "rails_helper"

describe PromoCampaign do
  describe "validations" do
    subject { build(:promo_campaign) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:start_at) }
    it { is_expected.to validate_presence_of(:finish_at) }
    it { is_expected.to validate_presence_of(:discount_rate) }
    it { is_expected.to validate_presence_of(:min_items_count) }
    it { is_expected.to validate_numericality_of(:discount_rate).only_integer.is_in(1..100) }
    it { is_expected.to validate_numericality_of(:min_items_count).only_integer.is_greater_than_or_equal_to(1) }

    context "when finish_at is before start_at" do
      let(:promo_campaign) { build(:promo_campaign, start_at: 1.day.from_now, finish_at: 1.day.ago) }

      it "is invalid" do
        expect(promo_campaign).not_to be_valid
        expect(promo_campaign.errors[:finish_at]).to be_present
      end
    end
  end

  describe "terms immutability" do
    context "when the campaign has started and the terms change" do
      let(:promo_campaign) do
        create(:promo_campaign, start_at: 1.day.ago).tap do |started_campaign|
          started_campaign.assign_attributes(
            kind: PromoCampaign::EACH_ITEM_DISCOUNT, discount_rate: 50, min_items_count: 3, start_at: 1.day.from_now
          )
        end
      end

      it "is invalid" do
        expect(promo_campaign).not_to be_valid
        expect(promo_campaign.errors.details).to include(
          kind: [{ error: :immutable_after_start }],
          discount_rate: [{ error: :immutable_after_start }],
          min_items_count: [{ error: :immutable_after_start }],
          start_at: [{ error: :immutable_after_start }]
        )
      end
    end

    context "when the campaign has started and only start_at moves to the future" do
      let(:promo_campaign) do
        create(:promo_campaign, start_at: 1.day.ago).tap do |started_campaign|
          started_campaign.start_at = 1.day.from_now
        end
      end

      it "is invalid" do
        expect(promo_campaign).not_to be_valid
        expect(promo_campaign.errors.details).to include(start_at: [{ error: :immutable_after_start }])
      end
    end

    context "when the campaign has started and only the title changes" do
      let(:promo_campaign) do
        create(:promo_campaign, start_at: 1.day.ago).tap { |started_campaign| started_campaign.title = "New title" }
      end

      it "is valid" do
        expect(promo_campaign).to be_valid
      end
    end

    context "when the campaign has not started and the terms change" do
      let(:promo_campaign) do
        create(:promo_campaign, :not_started).tap { |future_campaign| future_campaign.discount_rate = 50 }
      end

      it "is valid" do
        expect(promo_campaign).to be_valid
      end
    end
  end

  describe "#item_discount_for" do
    let(:promo_campaign) { build(:promo_campaign) }
    let(:order_item) { build(:order_item) }

    it "returns the item discount of the campaign for the order item" do
      expect(promo_campaign.item_discount_for(order_item))
        .to be_a(PromoCampaign::ItemDiscount).and have_attributes(promo_campaign:, order_item:)
    end
  end

  describe "#applicable" do
    let!(:applicable_campaign) { create(:promo_campaign) }

    before do
      create(:promo_campaign, :disabled)
      create(:promo_campaign, :pending)
      create(:promo_campaign, :finished)
      create(:promo_campaign, :not_started)
    end

    it "returns only enabled, ongoing and completed campaigns" do
      expect(described_class.applicable).to contain_exactly(applicable_campaign)
    end
  end

  describe "#ongoing" do
    before do
      freeze_time
      create(:promo_campaign, start_at: 2.days.ago, finish_at: 1.second.ago)
    end

    let!(:starts_now_campaign) { create(:promo_campaign, start_at: Time.current, finish_at: 1.day.from_now) }
    let!(:finishes_now_campaign) { create(:promo_campaign, start_at: 1.day.ago, finish_at: Time.current) }

    it "includes both start_at and finish_at" do
      expect(described_class.ongoing).to contain_exactly(starts_now_campaign, finishes_now_campaign)
    end
  end

  describe "#by_product_ids" do
    let(:fruit_tea) { create(:product) }
    let(:coffee) { create(:product) }
    let!(:fruit_tea_campaign) { create(:promo_campaign, with_products: [fruit_tea]) }

    before do
      create(:promo_campaign, with_products: [coffee])
      create(
        :promo_campaign_product_link, :inactive, promo_campaign: create(:promo_campaign), product: fruit_tea
      )
    end

    it "returns campaigns with an active link to one of the products" do
      expect(described_class.by_product_ids([fruit_tea.id])).to contain_exactly(fruit_tea_campaign)
    end
  end
end
