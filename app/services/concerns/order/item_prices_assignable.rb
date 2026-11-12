# frozen_string_literal: true

module Order::ItemPricesAssignable
  prepend MemoWise
  extend ActiveSupport::Concern

  private

  def product_prices(product)
    raise Errors::UnprocessableEntity, "Product #{product.sku} has no final price" if product.price.nil?

    { price: product.price.amount, min_recommended_price: product.min_recommended_price&.amount }
  end

  memo_wise def products_by_id
    Product.includes(:price, :min_recommended_price)
      .find(params[:items].pluck(:product_id).uniq)
      .index_by(&:id)
  end
end
