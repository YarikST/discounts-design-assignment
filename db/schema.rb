# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_11_170008) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "customers", force: :cascade do |t|
    t.string "full_name", null: false
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", null: false
    t.string "status", null: false
    t.bigint "price", null: false
    t.bigint "min_recommended_price"
    t.bigint "subtotal_price", null: false
    t.bigint "discount_amount", null: false
    t.bigint "total_price", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id", "product_id"], name: "index_order_items_on_order_id_and_product_id", unique: true
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "order_offers", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "order_item_id", null: false
    t.string "promotion_type", null: false
    t.bigint "promotion_id", null: false
    t.bigint "discount_amount", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_order_offers_on_discarded_at"
    t.index ["order_id"], name: "index_order_offers_on_order_id"
    t.index ["order_item_id", "promotion_type", "promotion_id"], name: "index_order_offers_on_order_item_and_promotion_kept", unique: true, where: "(discarded_at IS NULL)"
    t.index ["order_item_id"], name: "index_order_offers_on_order_item_id"
    t.index ["promotion_type", "promotion_id"], name: "index_order_offers_on_promotion"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "customer_id"
    t.string "currency", null: false
    t.bigint "subtotal_price", null: false
    t.bigint "discount_amount", null: false
    t.bigint "total_price", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_orders_on_customer_id"
  end

  create_table "product_prices", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.string "type", null: false
    t.bigint "amount", null: false
    t.string "currency", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "type"], name: "index_product_prices_on_product_id_and_type", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.string "sku", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sku"], name: "index_products_on_sku", unique: true
  end

  create_table "promo_campaign_product_links", force: :cascade do |t|
    t.bigint "promo_campaign_id", null: false
    t.bigint "product_id", null: false
    t.boolean "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_promo_campaign_product_links_on_product_id"
    t.index ["promo_campaign_id", "product_id"], name: "idx_on_promo_campaign_id_product_id_434b7f60da", unique: true
  end

  create_table "promo_campaigns", force: :cascade do |t|
    t.string "title", null: false
    t.string "kind", null: false
    t.integer "discount_rate", null: false
    t.integer "min_items_count", null: false
    t.boolean "enabled", null: false
    t.string "status", null: false
    t.datetime "start_at", null: false
    t.datetime "finish_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enabled"], name: "index_promo_campaigns_on_enabled"
    t.index ["start_at", "finish_at"], name: "index_promo_campaigns_on_start_at_and_finish_at"
    t.index ["status"], name: "index_promo_campaigns_on_status"
  end

  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "order_offers", "order_items"
  add_foreign_key "order_offers", "orders"
  add_foreign_key "orders", "customers"
  add_foreign_key "product_prices", "products"
  add_foreign_key "promo_campaign_product_links", "products"
  add_foreign_key "promo_campaign_product_links", "promo_campaigns"
end
