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

ActiveRecord::Schema[8.0].define(version: 2026_11_13_150000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "affiliate_attributions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "affiliate_user_id", null: false
    t.uuid "product_id", null: false
    t.uuid "buyer_user_id"
    t.uuid "affiliate_click_id"
    t.string "visitor_id"
    t.datetime "attributed_at", null: false
    t.datetime "expires_at", null: false
    t.datetime "converted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["affiliate_click_id"], name: "index_affiliate_attributions_on_affiliate_click_id"
    t.index ["affiliate_user_id"], name: "index_affiliate_attributions_on_affiliate_user_id"
    t.index ["buyer_user_id"], name: "index_affiliate_attributions_on_buyer_user_id"
    t.index ["converted_at"], name: "index_affiliate_attributions_on_converted_at"
    t.index ["expires_at"], name: "index_affiliate_attributions_on_expires_at"
    t.index ["product_id", "buyer_user_id"], name: "idx_affiliate_attr_unique_product_buyer", unique: true, where: "(buyer_user_id IS NOT NULL)"
    t.index ["product_id", "visitor_id"], name: "idx_affiliate_attr_unique_product_visitor", unique: true, where: "((buyer_user_id IS NULL) AND (visitor_id IS NOT NULL))"
    t.index ["product_id"], name: "index_affiliate_attributions_on_product_id"
  end

  create_table "affiliate_clicks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "affiliate_user_id", null: false
    t.uuid "product_id", null: false
    t.uuid "buyer_user_id"
    t.string "visitor_id"
    t.string "ip_hash"
    t.text "user_agent"
    t.text "referrer"
    t.datetime "clicked_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["affiliate_user_id"], name: "index_affiliate_clicks_on_affiliate_user_id"
    t.index ["buyer_user_id"], name: "index_affiliate_clicks_on_buyer_user_id"
    t.index ["clicked_at"], name: "index_affiliate_clicks_on_clicked_at"
    t.index ["product_id", "buyer_user_id"], name: "index_affiliate_clicks_on_product_id_and_buyer_user_id"
    t.index ["product_id", "visitor_id"], name: "index_affiliate_clicks_on_product_id_and_visitor_id"
    t.index ["product_id"], name: "index_affiliate_clicks_on_product_id"
  end

  create_table "affiliate_earnings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "affiliate_user_id", null: false
    t.uuid "buyer_user_id", null: false
    t.uuid "order_id", null: false
    t.uuid "order_item_id"
    t.uuid "product_id"
    t.uuid "affiliate_attribution_id"
    t.string "status", default: "pending", null: false
    t.decimal "sale_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "commission_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.string "currency", default: "GHS", null: false
    t.datetime "earned_at", null: false
    t.datetime "available_at"
    t.datetime "withdrawn_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "affiliate_signup_referral_id"
    t.string "earning_type", default: "product_commission", null: false
    t.index ["affiliate_attribution_id"], name: "index_affiliate_earnings_on_affiliate_attribution_id"
    t.index ["affiliate_signup_referral_id", "order_id"], name: "idx_affiliate_earnings_unique_signup_order", unique: true, where: "(affiliate_signup_referral_id IS NOT NULL)"
    t.index ["affiliate_signup_referral_id"], name: "index_affiliate_earnings_on_affiliate_signup_referral_id"
    t.index ["affiliate_user_id", "status"], name: "index_affiliate_earnings_on_affiliate_user_id_and_status"
    t.index ["affiliate_user_id"], name: "index_affiliate_earnings_on_affiliate_user_id"
    t.index ["buyer_user_id"], name: "index_affiliate_earnings_on_buyer_user_id"
    t.index ["earned_at"], name: "index_affiliate_earnings_on_earned_at"
    t.index ["earning_type"], name: "index_affiliate_earnings_on_earning_type"
    t.index ["order_id"], name: "index_affiliate_earnings_on_order_id"
    t.index ["order_item_id"], name: "index_affiliate_earnings_on_order_item_id", unique: true
    t.index ["product_id"], name: "index_affiliate_earnings_on_product_id"
    t.check_constraint "commission_amount >= 0::numeric", name: "affiliate_earnings_commission_amount_non_negative"
    t.check_constraint "sale_amount >= 0::numeric", name: "affiliate_earnings_sale_amount_non_negative"
  end

  create_table "affiliate_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "reviewed_by_id"
    t.string "status", default: "pending", null: false
    t.string "affiliate_code", null: false
    t.string "full_name"
    t.string "email"
    t.string "phone"
    t.string "country"
    t.string "city"
    t.jsonb "social_links", default: [], null: false
    t.jsonb "promotion_channels", default: [], null: false
    t.integer "audience_size"
    t.string "content_niche"
    t.text "reason"
    t.jsonb "payout_details", default: {}, null: false
    t.boolean "terms_accepted", default: false, null: false
    t.datetime "reviewed_at"
    t.text "rejection_reason"
    t.datetime "suspended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["affiliate_code"], name: "index_affiliate_profiles_on_affiliate_code", unique: true
    t.index ["reviewed_by_id"], name: "index_affiliate_profiles_on_reviewed_by_id"
    t.index ["status"], name: "index_affiliate_profiles_on_status"
    t.index ["user_id"], name: "index_affiliate_profiles_on_user_id", unique: true
    t.check_constraint "audience_size IS NULL OR audience_size >= 0", name: "affiliate_profiles_audience_size_non_negative"
  end

  create_table "affiliate_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "signup_referral_percentage", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "signup_referral_cap_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.boolean "signup_referral_enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "signup_referral_cap_amount >= 0::numeric", name: "affiliate_settings_signup_cap_non_negative"
    t.check_constraint "signup_referral_percentage >= 0::numeric", name: "affiliate_settings_signup_percentage_non_negative"
  end

  create_table "affiliate_signup_referrals", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "affiliate_user_id", null: false
    t.uuid "referred_user_id", null: false
    t.string "visitor_id"
    t.datetime "referred_at", null: false
    t.datetime "converted_at"
    t.integer "rewarded_orders_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["affiliate_user_id"], name: "index_affiliate_signup_referrals_on_affiliate_user_id"
    t.index ["converted_at"], name: "index_affiliate_signup_referrals_on_converted_at"
    t.index ["referred_user_id"], name: "index_affiliate_signup_referrals_on_referred_user_id", unique: true
    t.index ["visitor_id"], name: "index_affiliate_signup_referrals_on_visitor_id"
    t.check_constraint "rewarded_orders_count >= 0 AND rewarded_orders_count <= 3", name: "affiliate_signup_referrals_rewarded_orders_count_range"
  end

  create_table "affiliate_withdrawals", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "affiliate_user_id", null: false
    t.uuid "reviewed_by_id"
    t.string "status", default: "pending", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.string "currency", default: "GHS", null: false
    t.jsonb "payout_details", default: {}, null: false
    t.datetime "requested_at", null: false
    t.datetime "reviewed_at"
    t.datetime "paid_at"
    t.text "admin_note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["affiliate_user_id", "status"], name: "index_affiliate_withdrawals_on_affiliate_user_id_and_status"
    t.index ["affiliate_user_id"], name: "index_affiliate_withdrawals_on_affiliate_user_id"
    t.index ["requested_at"], name: "index_affiliate_withdrawals_on_requested_at"
    t.index ["reviewed_by_id"], name: "index_affiliate_withdrawals_on_reviewed_by_id"
    t.check_constraint "amount > 0::numeric", name: "affiliate_withdrawals_amount_positive"
  end

  create_table "assistant_challenges", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.string "shop_id", null: false
    t.string "ticket_digest", null: false
    t.string "email_digest", null: false
    t.string "code_digest", null: false
    t.string "auth_fingerprint"
    t.jsonb "context", default: {}, null: false
    t.integer "attempts", default: 0, null: false
    t.datetime "expires_at", null: false
    t.datetime "consumed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "email_digest", "created_at"], name: "assistant_challenges_email_window"
    t.index ["ticket_digest"], name: "index_assistant_challenges_on_ticket_digest", unique: true
    t.index ["user_id"], name: "index_assistant_challenges_on_user_id"
  end

  create_table "assistant_delegations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "shop_id", null: false
    t.string "audience", null: false
    t.jsonb "context", null: false
    t.string "code_digest", null: false
    t.string "grant_digest"
    t.datetime "issued_at", null: false
    t.datetime "expires_at", null: false
    t.datetime "consented_at", null: false
    t.string "policy_version", null: false
    t.datetime "consumed_at"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code_digest"], name: "index_assistant_delegations_on_code_digest", unique: true
    t.index ["grant_digest"], name: "index_assistant_delegations_on_grant_digest", unique: true
    t.index ["user_id"], name: "index_assistant_delegations_on_user_id"
  end

  create_table "badges", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "bonus_points", default: 0, null: false
    t.index ["name"], name: "index_badges_on_name", unique: true
    t.check_constraint "bonus_points >= 0", name: "badges_bonus_points_non_negative"
  end

  create_table "bonuses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.decimal "balance", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_bonuses_on_user_id", unique: true
  end

  create_table "cart_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "product_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "variant_stock_id"
    t.integer "quantity", default: 1, null: false
    t.index ["product_id"], name: "index_cart_items_on_product_id"
    t.index ["user_id", "product_id", "variant_stock_id"], name: "index_cart_items_on_user_product_variant", unique: true
    t.index ["user_id"], name: "index_cart_items_on_user_id"
    t.index ["variant_stock_id"], name: "index_cart_items_on_variant_stock_id"
    t.check_constraint "quantity > 0", name: "cart_items_quantity_positive"
  end

  create_table "categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "image_url"
    t.string "image_storage_key"
    t.index ["image_storage_key"], name: "index_categories_on_image_storage_key"
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "contact_messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "purpose", null: false
    t.text "message", null: false
    t.string "name", null: false
    t.string "email", null: false
    t.string "phone", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_contact_messages_on_created_at"
    t.index ["email"], name: "index_contact_messages_on_email"
    t.index ["name"], name: "index_contact_messages_on_name"
    t.index ["phone"], name: "index_contact_messages_on_phone"
  end

  create_table "customer_addresses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "name", null: false
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.string "country"
    t.string "region"
    t.string "city"
    t.string "county"
    t.jsonb "address", default: {}
    t.boolean "is_default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "town"
    t.string "market_name"
    t.uuid "delivery_zone_id"
    t.index ["address"], name: "index_customer_addresses_on_address", using: :gin
    t.index ["delivery_zone_id"], name: "index_customer_addresses_on_delivery_zone_id"
    t.index ["is_default"], name: "index_customer_addresses_on_is_default"
    t.index ["latitude", "longitude"], name: "index_customer_addresses_on_latitude_and_longitude"
    t.index ["market_name"], name: "index_customer_addresses_on_market_name"
    t.index ["name"], name: "index_customer_addresses_on_name"
    t.index ["town"], name: "index_customer_addresses_on_town"
    t.index ["user_id"], name: "index_customer_addresses_on_user_id"
  end

  create_table "delivery_high_value_rates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "pricing_zone", null: false
    t.string "shipping_category", null: false
    t.decimal "fee", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pricing_zone", "shipping_category"], name: "index_delivery_high_value_rates_on_zone_and_category", unique: true
    t.check_constraint "fee >= 0::numeric", name: "delivery_high_value_rates_fee_non_negative"
    t.check_constraint "pricing_zone::text = ANY (ARRAY['near'::character varying::text, 'far'::character varying::text])", name: "delivery_high_value_rates_pricing_zone_valid"
  end

  create_table "delivery_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.jsonb "value", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_delivery_settings_on_key", unique: true
  end

  create_table "delivery_weight_tiers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "pricing_zone", null: false
    t.decimal "min_weight_kg", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "max_weight_kg", precision: 10, scale: 2
    t.decimal "fee", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pricing_zone", "min_weight_kg", "max_weight_kg"], name: "index_delivery_weight_tiers_on_zone_and_weight"
    t.check_constraint "fee >= 0::numeric", name: "delivery_weight_tiers_fee_non_negative"
    t.check_constraint "max_weight_kg IS NULL OR max_weight_kg > min_weight_kg", name: "delivery_weight_tiers_max_above_min"
    t.check_constraint "min_weight_kg >= 0::numeric", name: "delivery_weight_tiers_min_weight_non_negative"
    t.check_constraint "pricing_zone::text = ANY (ARRAY['near'::character varying::text, 'far'::character varying::text])", name: "delivery_weight_tiers_pricing_zone_valid"
  end

  create_table "delivery_zones", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.string "pricing_zone", null: false
    t.string "region"
    t.string "city"
    t.string "station_name"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "town"
    t.string "market_name"
    t.boolean "region_open", default: false, null: false
    t.boolean "city_open", default: false, null: false
    t.boolean "town_open", default: false, null: false
    t.index ["city"], name: "index_delivery_zones_on_city"
    t.index ["code"], name: "index_delivery_zones_on_code", unique: true
    t.index ["market_name"], name: "index_delivery_zones_on_market_name"
    t.index ["pricing_zone"], name: "index_delivery_zones_on_pricing_zone"
    t.index ["region", "city", "town", "market_name"], name: "index_delivery_zones_on_location_hierarchy"
    t.index ["region"], name: "index_delivery_zones_on_region"
    t.index ["town"], name: "index_delivery_zones_on_town"
    t.check_constraint "pricing_zone::text = ANY (ARRAY['near'::character varying::text, 'far'::character varying::text])", name: "delivery_zones_pricing_zone_valid"
  end

  create_table "downtimes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "variant_stock_id", null: false
    t.datetime "start_at", null: false
    t.datetime "end_at", null: false
    t.datetime "ended_at"
    t.text "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["end_at"], name: "index_downtimes_on_end_at"
    t.index ["start_at"], name: "index_downtimes_on_start_at"
    t.index ["variant_stock_id"], name: "index_downtimes_on_variant_stock_id"
  end

  create_table "fulfillment_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "fulfillment_id", null: false
    t.uuid "order_item_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fulfillment_id", "order_item_id"], name: "index_fulfillment_items_on_fulfillment_and_booking_item", unique: true
    t.index ["fulfillment_id"], name: "index_fulfillment_items_on_fulfillment_id"
    t.index ["order_item_id"], name: "index_fulfillment_items_on_order_item_id"
  end

  create_table "fulfillments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "order_id", null: false
    t.uuid "warehouse_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "delivery_date"
    t.decimal "delivery_fee", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "warehouse_latitude", precision: 10, scale: 7
    t.decimal "warehouse_longitude", precision: 10, scale: 7
    t.index ["delivery_date"], name: "index_fulfillments_on_delivery_date"
    t.index ["order_id"], name: "index_fulfillments_on_order_id"
    t.index ["status"], name: "index_fulfillments_on_status"
    t.index ["warehouse_id"], name: "index_fulfillments_on_warehouse_id"
  end

  create_table "images", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "owner_type", null: false
    t.uuid "owner_id", null: false
    t.string "url", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "storage_key"
    t.index ["owner_type", "owner_id"], name: "index_images_on_owner"
    t.index ["owner_type", "owner_id"], name: "index_images_on_owner_type_and_owner_id"
    t.index ["storage_key"], name: "index_images_on_storage_key"
  end

  create_table "jwt_denylist", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.index ["jti"], name: "index_jwt_denylist_on_jti"
  end

  create_table "order_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "order_id", null: false
    t.uuid "variant_stock_id"
    t.integer "quantity", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "variant_stock_price", precision: 10, scale: 2
    t.integer "variant_stock_quantity"
    t.text "variant_stock_option_names"
    t.string "variant_stock_warehouse_name"
    t.jsonb "variant_stock_warehouse_address", default: {}
    t.decimal "variant_stock_warehouse_latitude", precision: 10, scale: 7
    t.decimal "variant_stock_warehouse_longitude", precision: 10, scale: 7
    t.string "variant_stock_warehouse_country"
    t.string "variant_stock_warehouse_region"
    t.string "variant_stock_warehouse_city"
    t.string "variant_stock_warehouse_county"
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["variant_stock_id"], name: "index_order_items_on_variant_stock_id"
  end

  create_table "orders", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "customer_address_id"
    t.decimal "delivery_distance", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "delivery_fee", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "item_subtotal", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "total_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.string "delivery_address_name"
    t.decimal "delivery_latitude", precision: 10, scale: 7
    t.decimal "delivery_longitude", precision: 10, scale: 7
    t.text "phones", default: [], array: true
    t.uuid "assigned_to_id"
    t.string "payment_status", default: "pending", null: false
    t.string "order_id", limit: 7, null: false
    t.datetime "bonus_points_awarded_at"
    t.datetime "received_bonus_awarded_at"
    t.datetime "terms_accepted_at"
    t.string "terms_version"
    t.index ["assigned_to_id"], name: "index_orders_on_assigned_to_id"
    t.index ["customer_address_id"], name: "index_orders_on_customer_address_id"
    t.index ["order_id"], name: "index_orders_on_order_id", unique: true
    t.index ["payment_status"], name: "index_orders_on_payment_status"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["terms_accepted_at"], name: "index_orders_on_terms_accepted_at"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "permissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_permissions_on_name", unique: true
  end

  create_table "product_categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "product_id", null: false
    t.uuid "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_product_categories_on_category_id"
    t.index ["product_id", "category_id"], name: "index_product_categories_on_product_id_and_category_id", unique: true
    t.index ["product_id"], name: "index_product_categories_on_product_id"
  end

  create_table "product_meta", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "product_id", null: false
    t.string "name", null: false
    t.string "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "name"], name: "index_product_meta_on_product_id_and_name"
    t.index ["product_id"], name: "index_product_meta_on_product_id"
  end

  create_table "product_sub_categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "product_id", null: false
    t.uuid "sub_category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "sub_category_id"], name: "index_product_sub_categories_on_product_id_and_sub_category_id", unique: true
    t.index ["product_id"], name: "index_product_sub_categories_on_product_id"
    t.index ["sub_category_id"], name: "index_product_sub_categories_on_sub_category_id"
  end

  create_table "products", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "bookable_type", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "category_id"
    t.string "status", default: "available"
    t.decimal "delivery_rate_per_km", precision: 10, scale: 2, default: "10.0", null: false
    t.integer "bonus_points", default: 0, null: false
    t.decimal "affiliate_commission_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.string "shipping_type", default: "bulk", null: false
    t.decimal "weight_kg", precision: 10, scale: 2
    t.string "weight_class", default: "medium", null: false
    t.string "shipping_category"
    t.text "search_keywords", default: [], null: false, array: true
    t.boolean "hot_deal", default: false, null: false
    t.text "condition_notes"
    t.decimal "compare_at_price", precision: 10, scale: 2
    t.boolean "demo", default: false, null: false
    t.index ["active"], name: "index_products_on_active"
    t.index ["bookable_type"], name: "index_products_on_bookable_type"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["hot_deal"], name: "index_products_on_hot_deal"
    t.index ["search_keywords"], name: "index_products_on_search_keywords", using: :gin
    t.index ["shipping_category"], name: "index_products_on_shipping_category"
    t.index ["shipping_type"], name: "index_products_on_shipping_type"
    t.index ["status"], name: "index_products_on_status"
    t.check_constraint "affiliate_commission_amount >= 0::numeric", name: "products_affiliate_commission_amount_non_negative"
    t.check_constraint "bonus_points >= 0", name: "products_bonus_points_non_negative"
    t.check_constraint "shipping_type::text = ANY (ARRAY['bulk'::character varying::text, 'high_value'::character varying::text])", name: "products_shipping_type_valid"
    t.check_constraint "weight_class IS NULL OR (weight_class::text = ANY (ARRAY['light'::character varying::text, 'medium'::character varying::text, 'heavy'::character varying::text]))", name: "products_weight_class_valid"
    t.check_constraint "weight_kg IS NULL OR weight_kg >= 0::numeric", name: "products_weight_kg_non_negative"
  end

  create_table "reviews", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "product_id", null: false
    t.uuid "user_id", null: false
    t.integer "points", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "user_id"], name: "index_reviews_on_product_id_and_user_id"
    t.index ["product_id"], name: "index_reviews_on_product_id"
    t.index ["user_id"], name: "index_reviews_on_user_id"
    t.check_constraint "points >= 0 AND points <= 5", name: "reviews_points_between_0_and_5"
  end

  create_table "roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "sub_categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "category_id", null: false
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "image_url"
    t.string "image_storage_key"
    t.index ["category_id", "name"], name: "index_sub_categories_on_category_id_and_name", unique: true
    t.index ["category_id"], name: "index_sub_categories_on_category_id"
    t.index ["image_storage_key"], name: "index_sub_categories_on_image_storage_key"
  end

  create_table "support_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.string "topic", null: false
    t.text "message", null: false
    t.string "guest_full_name"
    t.string "guest_email"
    t.string "guest_phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "pending", null: false
    t.index ["created_at"], name: "index_support_requests_on_created_at"
    t.index ["guest_email"], name: "index_support_requests_on_guest_email"
    t.index ["status"], name: "index_support_requests_on_status"
    t.index ["topic"], name: "index_support_requests_on_topic"
    t.index ["user_id"], name: "index_support_requests_on_user_id"
  end

  create_table "transactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "order_id"
    t.integer "amount_kobo", null: false
    t.string "currency", default: "GHS", null: false
    t.string "status", default: "initialized", null: false
    t.string "provider", default: "paystack", null: false
    t.string "provider_reference", null: false
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.uuid "affiliate_withdrawal_id"
    t.string "purpose", default: "order_payment", null: false
    t.string "direction", default: "credit", null: false
    t.datetime "processed_at"
    t.index ["affiliate_withdrawal_id"], name: "idx_transactions_unique_affiliate_withdrawal", unique: true, where: "(affiliate_withdrawal_id IS NOT NULL)"
    t.index ["affiliate_withdrawal_id"], name: "index_transactions_on_affiliate_withdrawal_id"
    t.index ["direction"], name: "index_transactions_on_direction"
    t.index ["order_id"], name: "index_transactions_on_order_id"
    t.index ["processed_at"], name: "index_transactions_on_processed_at"
    t.index ["provider_reference"], name: "index_transactions_on_provider_reference", unique: true
    t.index ["purpose"], name: "index_transactions_on_purpose"
    t.index ["status"], name: "index_transactions_on_status"
    t.index ["user_id"], name: "index_transactions_on_user_id"
    t.check_constraint "direction::text = ANY (ARRAY['credit'::character varying::text, 'debit'::character varying::text])", name: "transactions_direction_valid"
    t.check_constraint "order_id IS NOT NULL OR affiliate_withdrawal_id IS NOT NULL", name: "transactions_reference_present"
    t.check_constraint "purpose::text = ANY (ARRAY['order_payment'::character varying::text, 'affiliate_withdrawal_payout'::character varying::text])", name: "transactions_purpose_valid"
  end

  create_table "user_badges", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "badge_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["badge_id"], name: "index_user_badges_on_badge_id"
    t.index ["created_at"], name: "index_user_badges_on_created_at"
    t.index ["user_id", "badge_id"], name: "index_user_badges_on_user_id_and_badge_id", unique: true
    t.index ["user_id"], name: "index_user_badges_on_user_id"
  end

  create_table "user_permissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "permission_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["permission_id"], name: "index_user_permissions_on_permission_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "avatar"
    t.uuid "role_id"
    t.boolean "blocked", default: false, null: false
    t.boolean "otp_enabled", default: false, null: false
    t.string "otp_secret"
    t.datetime "otp_verified_at"
    t.string "provider"
    t.string "uid"
    t.text "phone_numbers", default: [], null: false, array: true
    t.string "avatar_storage_key"
    t.datetime "assistant_email_verified_at"
    t.index ["avatar_storage_key"], name: "index_users_on_avatar_storage_key"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true, where: "((provider IS NOT NULL) AND (uid IS NOT NULL))"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
  end

  create_table "variant_options", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "variant_type_id", null: false
    t.string "name", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "variant_type_id, lower((name)::text)", name: "index_variant_options_on_variant_type_id_and_lower_name", unique: true
    t.index ["variant_type_id"], name: "index_variant_options_on_variant_type_id"
  end

  create_table "variant_stocks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "option_ids", default: [], null: false, array: true
    t.integer "quantity", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "warehouse_id", null: false
    t.uuid "product_id"
    t.index ["option_ids"], name: "index_variant_stocks_on_option_ids", using: :gin
    t.index ["product_id"], name: "index_variant_stocks_on_product_id"
    t.index ["warehouse_id"], name: "index_variant_stocks_on_warehouse_id"
  end

  create_table "variant_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "product_id", null: false
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "pricing_role"
    t.index ["pricing_role"], name: "index_variant_types_on_pricing_role"
    t.index ["product_id"], name: "index_variant_types_on_product_id"
  end

  create_table "warehouses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.decimal "latitude", precision: 10, scale: 7, null: false
    t.decimal "longitude", precision: 10, scale: 7, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "country"
    t.string "region"
    t.string "city"
    t.string "county"
    t.jsonb "address", default: {}
    t.decimal "delivery_rate_per_km", precision: 10, scale: 2, default: "50.0", null: false
    t.index ["address"], name: "index_warehouses_on_address", using: :gin
    t.index ["city"], name: "index_warehouses_on_city"
    t.index ["country"], name: "index_warehouses_on_country"
    t.index ["county"], name: "index_warehouses_on_county"
    t.index ["latitude", "longitude"], name: "index_warehouses_on_latitude_and_longitude"
    t.index ["name"], name: "index_warehouses_on_name"
    t.index ["region"], name: "index_warehouses_on_region"
  end

  create_table "wishlist_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "product_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_wishlist_items_on_product_id"
    t.index ["user_id", "product_id"], name: "index_wishlist_items_on_user_id_and_product_id", unique: true
    t.index ["user_id"], name: "index_wishlist_items_on_user_id"
  end

  add_foreign_key "affiliate_attributions", "affiliate_clicks"
  add_foreign_key "affiliate_attributions", "products"
  add_foreign_key "affiliate_attributions", "users", column: "affiliate_user_id"
  add_foreign_key "affiliate_attributions", "users", column: "buyer_user_id"
  add_foreign_key "affiliate_clicks", "products"
  add_foreign_key "affiliate_clicks", "users", column: "affiliate_user_id"
  add_foreign_key "affiliate_clicks", "users", column: "buyer_user_id"
  add_foreign_key "affiliate_earnings", "affiliate_attributions"
  add_foreign_key "affiliate_earnings", "affiliate_signup_referrals"
  add_foreign_key "affiliate_earnings", "order_items"
  add_foreign_key "affiliate_earnings", "orders"
  add_foreign_key "affiliate_earnings", "products"
  add_foreign_key "affiliate_earnings", "users", column: "affiliate_user_id"
  add_foreign_key "affiliate_earnings", "users", column: "buyer_user_id"
  add_foreign_key "affiliate_profiles", "users"
  add_foreign_key "affiliate_profiles", "users", column: "reviewed_by_id"
  add_foreign_key "affiliate_signup_referrals", "users", column: "affiliate_user_id"
  add_foreign_key "affiliate_signup_referrals", "users", column: "referred_user_id"
  add_foreign_key "affiliate_withdrawals", "users", column: "affiliate_user_id"
  add_foreign_key "affiliate_withdrawals", "users", column: "reviewed_by_id"
  add_foreign_key "assistant_challenges", "users"
  add_foreign_key "assistant_delegations", "users"
  add_foreign_key "bonuses", "users"
  add_foreign_key "cart_items", "products"
  add_foreign_key "cart_items", "users"
  add_foreign_key "cart_items", "variant_stocks"
  add_foreign_key "customer_addresses", "delivery_zones"
  add_foreign_key "customer_addresses", "users"
  add_foreign_key "downtimes", "variant_stocks"
  add_foreign_key "fulfillment_items", "fulfillments"
  add_foreign_key "fulfillment_items", "order_items"
  add_foreign_key "fulfillments", "orders"
  add_foreign_key "fulfillments", "warehouses"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "variant_stocks", on_delete: :nullify
  add_foreign_key "orders", "customer_addresses"
  add_foreign_key "orders", "users"
  add_foreign_key "orders", "users", column: "assigned_to_id"
  add_foreign_key "product_categories", "categories"
  add_foreign_key "product_categories", "products"
  add_foreign_key "product_meta", "products"
  add_foreign_key "product_sub_categories", "products"
  add_foreign_key "product_sub_categories", "sub_categories"
  add_foreign_key "products", "categories"
  add_foreign_key "reviews", "products"
  add_foreign_key "reviews", "users"
  add_foreign_key "sub_categories", "categories"
  add_foreign_key "support_requests", "users"
  add_foreign_key "transactions", "affiliate_withdrawals"
  add_foreign_key "transactions", "orders"
  add_foreign_key "transactions", "users"
  add_foreign_key "user_badges", "badges"
  add_foreign_key "user_badges", "users"
  add_foreign_key "user_permissions", "permissions"
  add_foreign_key "user_permissions", "users"
  add_foreign_key "users", "roles"
  add_foreign_key "variant_options", "variant_types"
  add_foreign_key "variant_stocks", "products"
  add_foreign_key "variant_stocks", "warehouses"
  add_foreign_key "variant_types", "products"
  add_foreign_key "wishlist_items", "products"
  add_foreign_key "wishlist_items", "users"
end
