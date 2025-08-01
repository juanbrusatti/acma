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

ActiveRecord::Schema[8.0].define(version: 2025_07_29_032005) do
  create_table "dvhs", force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "innertube"
    t.float "height"
    t.float "width"
    t.string "location"
    t.decimal "price"
    t.string "glasscutting1_type"
    t.string "glasscutting1_thickness"
    t.string "glasscutting1_color"
    t.string "glasscutting2_type"
    t.string "glasscutting2_thickness"
    t.string "glasscutting2_color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "typology"
    t.index ["project_id"], name: "index_dvhs_on_project_id"
  end

  create_table "glass_prices", force: :cascade do |t|
    t.string "color"
    t.string "glass_type"
    t.string "thickness"
    t.decimal "buying_price"
    t.decimal "selling_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "percentage", precision: 5, scale: 2
  end

  create_table "glasscuttings", force: :cascade do |t|
    t.float "height"
    t.float "width"
    t.string "color"
    t.string "glass_type"
    t.string "thickness"
    t.string "location"
    t.decimal "price"
    t.integer "project_id", null: false
    t.integer "dvh_id"
    t.integer "glassplate_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sequential_id"
    t.string "typology"
    t.index ["dvh_id"], name: "index_glasscuttings_on_dvh_id"
    t.index ["glassplate_id"], name: "index_glasscuttings_on_glassplate_id"
    t.index ["project_id"], name: "index_glasscuttings_on_project_id"
  end

  create_table "glassplates", force: :cascade do |t|
    t.float "width"
    t.float "height"
    t.string "color"
    t.string "glass_type"
    t.string "thickness"
    t.string "standard_measures"
    t.string "location"
    t.string "work"
    t.string "origin"
    t.string "status"
    t.boolean "deleted", default: false
    t.boolean "is_scrap"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "projects", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "status", default: "Pendiente"
    t.date "delivery_date"
    t.string "phone"
    t.string "address"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.decimal "price"
    t.decimal "priceWithoutIva"
    t.decimal "price_without_iva"
  end

  create_table "supplies", force: :cascade do |t|
    t.string "name"
    t.decimal "price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "dvhs", "projects"
  add_foreign_key "glasscuttings", "dvhs"
  add_foreign_key "glasscuttings", "glassplates"
  add_foreign_key "glasscuttings", "projects"
end
