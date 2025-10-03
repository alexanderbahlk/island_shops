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

ActiveRecord::Schema[7.1].define(version: 2025_10_03_231020) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.string "title", null: false
    t.string "slug", null: false
    t.integer "category_type", default: 0, null: false
    t.bigint "parent_id"
    t.integer "sort_order", default: 0
    t.string "path"
    t.integer "depth", default: 0
    t.integer "lft", null: false
    t.integer "rgt", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "synonyms", default: [], array: true
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["category_type"], name: "index_categories_on_category_type"
    t.index ["lft", "rgt"], name: "index_categories_on_lft_and_rgt"
    t.index ["parent_id", "slug"], name: "index_categories_on_parent_id_and_slug", unique: true
    t.index ["parent_id", "sort_order"], name: "index_categories_on_parent_id_and_sort_order"
    t.index ["parent_id"], name: "index_categories_on_parent_id"
    t.index ["path"], name: "index_categories_on_path"
    t.index ["uuid"], name: "index_categories_on_uuid", unique: true
  end

  create_table "categories_shopping_lists", id: false, force: :cascade do |t|
    t.bigint "shopping_list_id", null: false
    t.bigint "category_id", null: false
    t.index ["category_id", "shopping_list_id"], name: "index_shopping_lists_categories_on_category_and_list"
    t.index ["shopping_list_id", "category_id"], name: "index_shopping_lists_categories_on_list_and_category", unique: true
  end

  create_table "locations", force: :cascade do |t|
    t.string "title", null: false
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.text "description"
    t.boolean "is_online", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["title"], name: "index_locations_on_title", unique: true
    t.index ["uuid"], name: "index_locations_on_uuid", unique: true
  end

  create_table "shop_item_updates", force: :cascade do |t|
    t.decimal "price", precision: 10, scale: 2, null: false
    t.decimal "price_per_unit", precision: 10, scale: 2
    t.string "stock_status"
    t.bigint "shop_item_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "normalized_unit"
    t.index ["shop_item_id"], name: "index_shop_item_updates_on_shop_item_id"
  end

  create_table "shop_items", force: :cascade do |t|
    t.string "url", null: false
    t.string "title", null: false
    t.string "display_title"
    t.string "image_url"
    t.decimal "size", precision: 10, scale: 2
    t.string "unit"
    t.string "product_id"
    t.boolean "approved", default: false
    t.boolean "needs_another_review", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "category_id"
    t.string "breadcrumb"
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.bigint "location_id"
    t.index ["breadcrumb"], name: "index_shop_items_on_breadcrumb"
    t.index ["category_id"], name: "index_shop_items_on_category_id"
    t.index ["location_id"], name: "index_shop_items_on_location_id"
    t.index ["url"], name: "index_shop_items_on_url", unique: true
    t.index ["uuid"], name: "index_shop_items_on_uuid", unique: true
  end

  create_table "shopping_list_items", force: :cascade do |t|
    t.string "title", null: false
    t.bigint "category_id"
    t.bigint "shopping_list_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.boolean "purchased", default: false, null: false
    t.integer "quantity", default: 1, null: false
    t.boolean "priority", default: false, null: false
    t.bigint "user_id", null: false
    t.bigint "shop_item_id"
    t.index ["category_id"], name: "index_shopping_list_items_on_category_id"
    t.index ["shop_item_id"], name: "index_shopping_list_items_on_shop_item_id"
    t.index ["user_id"], name: "index_shopping_list_items_on_user_id"
    t.index ["uuid"], name: "index_shopping_list_items_on_uuid", unique: true
  end

  create_table "shopping_list_users", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "shopping_list_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shopping_list_id"], name: "index_shopping_list_users_on_shopping_list_id"
    t.index ["user_id", "shopping_list_id"], name: "index_shopping_list_users_on_user_id_and_shopping_list_id", unique: true
    t.index ["user_id"], name: "index_shopping_list_users_on_user_id"
  end

  create_table "shopping_lists", force: :cascade do |t|
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "display_name", null: false
    t.bigint "user_id", null: false
    t.index ["slug"], name: "index_shopping_lists_on_slug", unique: true
    t.index ["user_id"], name: "index_shopping_lists_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "app_hash"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "group_shopping_lists_items_by"
    t.bigint "active_shopping_list_id"
    t.index ["active_shopping_list_id"], name: "index_users_on_active_shopping_list_id"
  end

  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "shop_item_updates", "shop_items"
  add_foreign_key "shop_items", "categories"
  add_foreign_key "shop_items", "locations"
  add_foreign_key "shopping_list_items", "shop_items"
  add_foreign_key "shopping_list_items", "shopping_lists"
  add_foreign_key "shopping_list_items", "users"
  add_foreign_key "shopping_list_users", "shopping_lists"
  add_foreign_key "shopping_list_users", "users"
  add_foreign_key "shopping_lists", "users"
  add_foreign_key "users", "shopping_lists", column: "active_shopping_list_id"
end
