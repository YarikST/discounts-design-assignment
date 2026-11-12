# frozen_string_literal: true

products_by_sku = [
  { sku: "FR", name: "Fruit Tea", price: 3_11 },
  { sku: "SR", name: "Strawberries", price: 5_00 },
  { sku: "CF", name: "Coffee", price: 11_23 },
  { sku: "AJ", name: "Apple Juice", price: 7_25 }
].to_h do |attributes|
  product = Product.find_or_create_by!(sku: attributes[:sku]) { it.name = attributes[:name] }
  product.price || product.create_price!(type: Product::Price::FINAL, amount: attributes[:price])

  [product.sku, product]
end

[
  {
    title: "Fruit Tea: buy one, get one free",
    kind: PromoCampaign::ONE_ITEM_DISCOUNT,
    discount_rate: 100,
    min_items_count: 2,
    skus: ["FR"]
  },
  {
    title: "Strawberries: 3 or more for $4.50 each",
    kind: PromoCampaign::EACH_ITEM_DISCOUNT,
    discount_rate: 10,
    min_items_count: 3,
    skus: ["SR"]
  }
].each do |attributes|
  promo_campaign = PromoCampaign.find_or_create_by!(title: attributes[:title]) do |new_campaign|
    new_campaign.assign_attributes(
      attributes.slice(:kind, :discount_rate, :min_items_count).merge(
        status: PromoCampaign::COMPLETED, start_at: 1.day.ago, finish_at: 1.year.from_now
      )
    )
  end

  attributes[:skus].each do |sku|
    promo_campaign.product_links.find_or_create_by!(product: products_by_sku.fetch(sku))
  end
end
