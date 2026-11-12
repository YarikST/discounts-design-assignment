# frozen_string_literal: true

class Checkout
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :products, default: -> { [] }
  attribute :customer

  def create_order
    raise Errors::UnprocessableEntity, "Checkout has no products" if products.empty?

    Order::Creator.new(params: { customer:, items: }).call
  end

  private

  def items
    products.map(&:id).tally.map { |product_id, quantity| { product_id:, quantity: } }
  end
end
