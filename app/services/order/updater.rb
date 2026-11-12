# frozen_string_literal: true

class Order::Updater < BaseService
  include Order::ItemPricesAssignable

  option :order
  option :params

  def call
    params[:items].each { |item_attributes| assign_item(item_attributes) }

    Order.transaction do
      SaleEngine.new(order:).call
      order.save!
    end

    order
  end

  private

  def assign_item(item_attributes)
    product = products_by_id.fetch(item_attributes[:product_id])
    item = order.items.find { it.product_id == product.id }

    if item
      item.assign_attributes(item_attributes)
    else
      order.items.build(**item_attributes, **product_prices(product), product:)
    end
  end
end
