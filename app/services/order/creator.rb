# frozen_string_literal: true

class Order::Creator < BaseService
  include Order::ItemPricesAssignable

  option :params

  def call
    order = Order.new(customer: params[:customer])
    build_items(order)

    Order.transaction do
      SaleEngine.new(order:).call
      order.save!
    end

    order
  end

  private

  def build_items(order)
    params[:items].each do |item_attributes|
      product = products_by_id.fetch(item_attributes[:product_id])

      order.items.build(**item_attributes, **product_prices(product), product:)
    end
  end
end
