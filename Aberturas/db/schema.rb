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

ActiveRecord::Schema[8.0].define(version: 2025_07_18_205037) do
  create_table "dvhs", force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "innertube"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.index ["project_id"], name: "index_dvhs_on_project_id"
  end

  create_table "glasscuttings", force: :cascade do |t|
    t.float "height"
    t.float "width"
    t.string "color"
    t.string "glass_type"
    t.string "location"
    t.decimal "price"
    t.integer "project_id", null: false
    t.integer "dvh_id"
    t.integer "glassplate_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "thickness"
    t.index ["dvh_id"], name: "index_glasscuttings_on_dvh_id"
    t.index ["glassplate_id"], name: "index_glasscuttings_on_glassplate_id"
    t.index ["project_id"], name: "index_glasscuttings_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status"
    t.date "delivery_date"
    t.string "phone"
    t.string "address"
  end
end
