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

ActiveRecord::Schema[8.1].define(version: 2026_08_18_032601) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vector"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "chunks", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "document_id", null: false
    t.vector "embedding", limit: 3072
    t.integer "position", default: 0, null: false
    t.integer "token_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_chunks_on_document_id"
  end

  create_table "documents", force: :cascade do |t|
    t.integer "chunk_count", default: 0, null: false
    t.string "content_type"
    t.datetime "created_at", null: false
    t.text "error"
    t.integer "file_size"
    t.datetime "processed_at"
    t.string "status", default: "queued", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "word_count"
  end

  create_table "providers", force: :cascade do |t|
    t.boolean "active", default: false, null: false
    t.string "api_key", default: "", null: false
    t.string "api_version"
    t.string "base_url"
    t.string "chat_model"
    t.datetime "created_at", null: false
    t.integer "embedding_dimensions", default: 1536
    t.string "embedding_model"
    t.boolean "enabled", default: true, null: false
    t.string "name", null: false
    t.string "notes"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_providers_on_slug", unique: true
  end

  create_table "queries", force: :cascade do |t|
    t.text "answer"
    t.integer "completion_tokens"
    t.datetime "created_at", null: false
    t.bigint "document_id"
    t.integer "latency_ms"
    t.string "model"
    t.integer "prompt_tokens"
    t.bigint "provider_id"
    t.text "question", null: false
    t.jsonb "sources", default: []
    t.string "status", default: "processing", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["document_id"], name: "index_queries_on_document_id"
    t.index ["provider_id"], name: "index_queries_on_provider_id"
    t.index ["user_id"], name: "index_queries_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.string "role", default: "user", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "chunks", "documents"
  add_foreign_key "queries", "documents"
  add_foreign_key "queries", "providers"
  add_foreign_key "queries", "users"
  add_foreign_key "sessions", "users"
end
