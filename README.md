# Discounts checkout

A grocery checkout with promo campaigns that marketing can extend without code changes.

```ruby
products = %w[FR SR FR FR CF].map { Product.find_by!(sku: it) }
order = Checkout.new(products:).create_order
order.total_price # => 2245 (cents, $22.45)
```

## What is done

- Products with prices (`final` and `min_recommended_price`), stored in integer cents.
- Promo campaigns as data: marketing creates a `PromoCampaign`, links it to products and sets its terms
  (`kind`, `discount_rate`, `min_items_count`, `start_at`, `finish_at`). Two kinds cover the assignment rules:
  - `one_item_discount`: one unit per order gets the discount (Fruit Tea: buy one, get one free);
  - `each_item_discount`: every unit gets the discount (Strawberries: 3 or more for $4.50 each).
- Both rules apply to the same checkout independently. Several campaigns can apply to one product.
- A discount never takes an item below its minimum recommended price; the checkout applies as much as it can.
- Every applied discount is saved as an `Order::Offer` per order item, so the order explains its discounts.
- Order update (`Order::Updater`): change quantities, refuse items, add products. The order keeps the campaigns it
  already got, even if a campaign was disabled, ended or lost its product links since.
- Rake tasks to check the current offers and to create an order from SKUs.

## Requirements

- Ruby 4.0.9
- PostgreSQL 14 or newer

## Setup

```sh
bundle install
bin/rails db:prepare
```

`db:prepare` creates the database, runs the migrations and loads the seeds. The seeds create the products and the
two campaigns from the assignment:

| SKU | Product | Price |
|---|---|---|
| FR | Fruit Tea | $3.11 |
| SR | Strawberries | $5.00 |
| CF | Coffee | $11.23 |
| AJ | Apple Juice | $7.25 |

| Campaign | Rule |
|---|---|
| Fruit Tea: buy one, get one free | 2 or more FR in the order → one FR is free (one per order) |
| Strawberries: 3 or more for $4.50 each | 3 or more SR in the order → each SR costs $4.50 (10% off) |

## Check the offers

Print the campaigns that apply now:

```sh
bin/rails checkout:offers
```

```
Fruit Tea: buy one, get one free (one_item_discount, 100% from 2 items): FR
Strawberries: 3 or more for $4.50 each (each_item_discount, 10% from 3 items): SR
```

Create an order from SKUs and print its items, offers and totals:

```sh
bin/rails "checkout:create_order[FR,SR,FR,FR,CF]"
```

```
Order #1
  FR x3: $9.33 - $3.11 = $6.22
    Fruit Tea: buy one, get one free: -$3.11
  SR x1: $5.00 - $0.00 = $5.00
  CF x1: $11.23 - $0.00 = $11.23
Subtotal: $25.56
Discount: $3.11
Total:    $22.45
```

The other examples from the assignment:

```sh
bin/rails "checkout:create_order[FR,FR]"          # Total: $3.11
bin/rails "checkout:create_order[SR,SR,FR,SR]"    # Total: $16.61
bin/rails "checkout:create_order[FR,FR,FR,FR]"    # Total: $9.33 (one free FR per order)
```

- Keep the quotes: zsh reads the square brackets as a file pattern.
- Do not put spaces between the SKUs.
- Every run saves a new order to the database.

## Architecture

```
Checkout ──► Order::Creator ─┐
                              ├─► SaleEngine ──► SaleEngine::PromoCampaignApplier ──► PromoCampaign::ItemDiscount
             Order::Updater ─┘        │
                                      └─► writes Order::Offer records; the services save the order in one transaction
```

### Models

| Model | Responsibility |
|---|---|
| `Product`, `Product::Price` | Catalogue. Price types `final` and `min_recommended_price` in one table. |
| `PromoCampaign` | Campaign terms. Terms cannot change after the campaign starts. |
| `PromoCampaign::ProductLink` | Links a campaign to a product, with an `active` flag. |
| `PromoCampaign::ItemDiscount` | Tableless model: the discount of one campaign for one order item. |
| `Checkout` | Tableless model: groups the scanned products into items and creates the order. |
| `Order`, `Order::Item`, `Order::Offer` | The result. Items keep copies of the product prices; offers keep the applied discounts. |
| `Customer` | Minimal customer; an order can be without one. |

### Services

| Service | Responsibility |
|---|---|
| `Order::Creator` | Builds the order and its items, runs `SaleEngine`, saves everything in one transaction. |
| `Order::Updater` | Changes the items of an existing order, runs `SaleEngine`, saves everything in one transaction. |
| `SaleEngine` | Runs the pricing steps in a fixed order. Finds the campaigns and writes the offers of each step. |
| `SaleEngine::PromoCampaignApplier` | Finds the items one campaign covers and calculates their discounts in memory. |

Only `Order::Creator` and `Order::Updater` write orders, items and offers. `SaleEngine` changes the records in
memory only.

### Concerns

| Concern | Responsibility |
|---|---|
| `PromoCampaign::Scopable` | Scopes `enabled`, `ongoing`, `applicable`, `by_product_ids`. |
| `Order::Item::Discountable` | Discounts of one item: the calculated discounts and the MRP cap. |
| `Order::ItemPricesAssignable` | Service concern: finds the products of the params and copies their prices to new items. |

## Tests and code style

```sh
bundle exec rspec
bundle exec rubocop
```

Set `COVERAGE=true` to get a coverage report.

## Add a new offer

- **A new campaign with the same rule types:** create a `PromoCampaign` with `status: completed` and link it to
  products. No code is needed.
- **A new rule type:**
  1. Add a value to `PromoCampaign::KINDS`.
  2. Add its branch in `PromoCampaign::ItemDiscount#discounted_items_count`. If the calculation is different, add a
     new class with the same interface and return it from `PromoCampaign#item_discount_for`.
  3. Add a migration only if the rule needs new terms.
- **A new discount type** (for example, a promocode): add a step to `SaleEngine` with its own applier and its own
  `Order::Offer` records (`promotion` is polymorphic).

## Open questions for the business

Each question shows the current behaviour in brackets.

- If several discounts apply to one product, do we apply all of them, only the best one, or a fixed priority? *(all of them, one by one, capped by the price)*
- If a product is in two campaigns at once, which one wins: the bigger discount, the campaign that ends sooner, or a
  fixed priority (brand before category)? *(both apply one by one)*
- Can a product that already got one promo (for example, a free unit) take part in another promo in the same
  order? *(yes)*
- "Buy one, get one free": one free unit per order or one per pair? *(one per order)*
- How many times can one campaign apply per order, and per customer over time? *(once per order for
  `one_item_discount`, no customer limit)*
- When a campaign cannot apply because of its limit, do we show it to the customer as "not applied" or hide it?
- Does a campaign have a budget, and what happens when it is spent: stop it, or warn marketing at some level (for
  example, 85%)? *(no budget)*
- How do we show discounts to customers (cart breakdown, receipt)?
- Do we prompt customers to add more items to get a promo (banner, product badges)?
- Marketing sees "the item is free", but finance wants the discount spread over all items (because of MRP and
  returns). Which model is the source of truth for `order_items.discount_amount`? *(the free item gets the whole
  discount)*
