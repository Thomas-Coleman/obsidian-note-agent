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

ActiveRecord::Schema[8.1].define(version: 2025_12_13_183524) do
  create_table "captures", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "content", size: :medium, null: false
    t.string "content_type", default: "conversation"
    t.string "context"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.text "key_points"
    t.text "markdown_content", size: :medium
    t.json "metadata"
    t.string "obsidian_folder", default: "Captures"
    t.string "obsidian_path"
    t.datetime "published_at"
    t.integer "status", default: 0, null: false
    t.text "summary", size: :medium
    t.json "tags"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["created_at"], name: "index_captures_on_created_at"
    t.index ["status"], name: "index_captures_on_status"
    t.index ["user_id"], name: "index_captures_on_user_id"
  end

  create_table "templates", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_default", default: false
    t.text "markdown_template", size: :medium
    t.string "name", null: false
    t.text "prompt_template", size: :medium, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "name"], name: "index_templates_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_templates_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "api_token", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "obsidian_vault_path", default: "/Users/tomcoleman/Documents/Obsidian/Tom's Obsidian Notes"
    t.datetime "updated_at", null: false
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "captures", "users"
  add_foreign_key "templates", "users"
end
