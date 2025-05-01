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

ActiveRecord::Schema.define(version: 2025_05_01_130826) do

  create_table "feature_toggle_client_settings", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "status", null: false
    t.string "client_uuid"
    t.json "extra_data"
    t.bigint "feature_toggle_settings_id"
    t.index ["client_uuid", "feature_toggle_settings_id"], name: "index_feature_settings_on_feature_toggle_settings", unique: true
    t.index ["feature_toggle_settings_id"], name: "index_feature_client_on_feature_toggle_settings"
  end

  create_table "feature_toggle_global_settings", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "status", null: false
    t.string "name", null: false
    t.json "extra_data"
    t.index ["name"], name: "index_feature_toggle_global_settings_on_name", unique: true
  end

end
