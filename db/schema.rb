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

ActiveRecord::Schema[7.2].define(version: 2026_06_04_220000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "vector"

  create_table "campaign_memories", force: :cascade do |t|
    t.bigint "campaign_id", null: false
    t.string "memory_type", null: false
    t.string "entity_name"
    t.string "aspect"
    t.text "summary", null: false
    t.integer "importance", default: 1
    t.string "chapter_id"
    t.integer "turn_number"
    t.vector "embedding", limit: 1536
    t.datetime "created_at", null: false
    t.index ["campaign_id", "entity_name"], name: "index_campaign_memories_on_campaign_id_and_entity_name"
    t.index ["campaign_id", "importance"], name: "index_campaign_memories_on_campaign_id_and_importance"
    t.index ["campaign_id", "memory_type"], name: "index_campaign_memories_on_campaign_id_and_memory_type"
    t.index ["campaign_id"], name: "index_campaign_memories_on_campaign_id"
  end

  create_table "campaigns", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.bigint "owner_id", null: false
    t.string "status", default: "setup", null: false
    t.string "files_path", null: false
    t.boolean "world_configured", default: false
    t.datetime "started_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_campaigns_on_owner_id"
    t.index ["slug"], name: "index_campaigns_on_slug", unique: true
    t.index ["status"], name: "index_campaigns_on_status"
  end

  create_table "characters", force: :cascade do |t|
    t.bigint "campaign_id", null: false
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "character_class", null: false
    t.integer "level", default: 1, null: false
    t.integer "current_xp", default: 0, null: false
    t.boolean "level_up_pending", default: false
    t.string "files_path", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id", "user_id"], name: "index_characters_on_campaign_id_and_user_id", unique: true
    t.index ["campaign_id"], name: "index_characters_on_campaign_id"
    t.index ["user_id"], name: "index_characters_on_user_id"
  end

  create_table "jwt_denylist", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.index ["jti"], name: "index_jwt_denylist_on_jti", unique: true
  end

  create_table "turns", force: :cascade do |t|
    t.bigint "campaign_id", null: false
    t.bigint "character_id", null: false
    t.integer "turn_number", null: false
    t.text "player_action", null: false
    t.text "gm_narrative", null: false
    t.jsonb "mechanic_result"
    t.jsonb "game_events", default: []
    t.datetime "created_at", null: false
    t.index ["campaign_id", "turn_number"], name: "index_turns_on_campaign_id_and_turn_number", unique: true
    t.index ["campaign_id"], name: "index_turns_on_campaign_id"
    t.index ["character_id"], name: "index_turns_on_character_id"
    t.index ["game_events"], name: "index_turns_on_game_events", using: :gin
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", default: "player", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "world_lore_embeddings", force: :cascade do |t|
    t.bigint "campaign_id", null: false
    t.text "content", null: false
    t.string "chunk_id", null: false
    t.vector "embedding", limit: 1536
    t.datetime "created_at", null: false
    t.index ["campaign_id", "chunk_id"], name: "index_world_lore_embeddings_on_campaign_id_and_chunk_id", unique: true
    t.index ["campaign_id"], name: "index_world_lore_embeddings_on_campaign_id"
  end
end
