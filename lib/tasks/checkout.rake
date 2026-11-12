# frozen_string_literal: true

namespace :checkout do
  format_money = ->(cents) { format("$%.2f", cents / 100.0) }

  desc "Print the promo campaigns that apply now"
  task offers: :environment do
    PromoCampaign.applicable.includes(:products).order(:id).each do |promo_campaign|
      puts "#{promo_campaign.title} (#{promo_campaign.kind}, #{promo_campaign.discount_rate}% " \
           "from #{promo_campaign.min_items_count} items): #{promo_campaign.products.map(&:sku).join(', ')}"
    end
  end

  desc "Create an order from product SKUs and print it"
  task create_order: :environment do |_task, arguments|
    products = arguments.extras.map { |sku| Product.find_by!(sku:) }
    order = Checkout.new(products:).create_order

    puts "Order ##{order.id}"
    order.items.includes(:product, offers: :promotion).find_each do |item|
      puts "  #{item.product.sku} x#{item.quantity}: #{format_money.call(item.subtotal_price)} " \
           "- #{format_money.call(item.discount_amount)} = #{format_money.call(item.total_price)}"
      item.offers.kept.each do |offer|
        puts "    #{offer.promotion.title}: -#{format_money.call(offer.discount_amount)}"
      end
    end
    puts "Subtotal: #{format_money.call(order.subtotal_price)}"
    puts "Discount: #{format_money.call(order.discount_amount)}"
    puts "Total:    #{format_money.call(order.total_price)}"
  end
end
