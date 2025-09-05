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

ActiveRecord::Schema[7.1].define(version: 2025_09_05_144352) do
  # These are extensions that must be enabled in order to support this database
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

  create_table "shop_item_categories", force: :cascade do |t|
    t.string "title", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["title"], name: "index_shop_item_categories_on_title"
  end

  create_table "shop_item_sub_categories", force: :cascade do |t|
    t.string "title", null: false
    t.bigint "shop_item_category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_item_category_id", "title"], name: "idx_on_shop_item_category_id_title_46d450a20d", unique: true
    t.index ["shop_item_category_id"], name: "index_shop_item_sub_categories_on_shop_item_category_id"
    t.index ["title"], name: "index_shop_item_sub_categories_on_title"
  end

  create_table "shop_item_sub_category_types", force: :cascade do |t|
    t.bigint "shop_item_sub_category_id", null: false
    t.bigint "shop_item_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_item_sub_category_id", "shop_item_type_id"], name: "index_sub_category_types_unique", unique: true
    t.index ["shop_item_sub_category_id"], name: "idx_on_shop_item_sub_category_id_7ec89870ff"
    t.index ["shop_item_type_id"], name: "index_shop_item_sub_category_types_on_shop_item_type_id"
  end

  create_table "shop_item_types", force: :cascade do |t|
    t.string "title", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["title"], name: "index_shop_item_types_on_title"
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
    t.string "shop", null: false
    t.string "url", null: false
    t.string "title", null: false
    t.string "display_title"
    t.string "image_url"
    t.decimal "size", precision: 10, scale: 2
    t.string "unit"
    t.string "location"
    t.string "product_id"
    t.boolean "approved", default: false
    t.boolean "needs_another_review", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "shop_item_type_id"
    t.index ["shop_item_type_id"], name: "index_shop_items_on_shop_item_type_id"
    t.index ["url"], name: "index_shop_items_on_url", unique: true
  end

  add_foreign_key "shop_item_sub_categories", "shop_item_categories"
  add_foreign_key "shop_item_sub_category_types", "shop_item_sub_categories"
  add_foreign_key "shop_item_sub_category_types", "shop_item_types"
  add_foreign_key "shop_item_updates", "shop_items"
  add_foreign_key "shop_items", "shop_item_types"
end
