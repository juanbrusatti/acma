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

ActiveRecord::Schema[8.0].define(version: 2025_07_15_223821) do
  create_table "glassplates", force: :cascade do |t|
    t.float "width"
    t.float "height"
    t.string "color"
    t.string "glass_type"
    t.boolean "deleted", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "thickness"
    t.string "standard_measures"
    t.integer "quantity"
    t.string "location"
    t.string "status"
    t.boolean "is_scrap"
  end

  create_table "insumos", force: :cascade do |t|
    t.string "nombre"
    t.decimal "precio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "precio_vidrios", force: :cascade do |t|
    t.string "color"
    t.string "tipo"
    t.decimal "grosor"
    t.decimal "precio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "precio_m2"
  end

  create_table "projects", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status"
    t.date "delivery_date"
  end
end
