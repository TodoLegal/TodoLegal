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


ActiveRecord::Schema[7.1].define(version: 2023_11_10_060208) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "fuzzystrmatch"
  enable_extension "pg_trgm"
  enable_extension "plpgsql"
  enable_extension "unaccent"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "alternative_tag_names", force: :cascade do |t|
    t.integer "tag_id"
    t.string "alternative_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id", "alternative_name"], name: "index_alternative_tag_names_on_tag_id_and_alternative_name", unique: true
  end

  create_table "articles", force: :cascade do |t|
    t.string "number"
    t.text "body"
    t.integer "position"
    t.integer "law_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "blazer_audits", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "query_id"
    t.text "statement"
    t.string "data_source"
    t.datetime "created_at"
    t.index ["query_id"], name: "index_blazer_audits_on_query_id"
    t.index ["user_id"], name: "index_blazer_audits_on_user_id"
  end

  create_table "blazer_checks", force: :cascade do |t|
    t.bigint "creator_id"
    t.bigint "query_id"
    t.string "state"
    t.string "schedule"
    t.text "emails"
    t.text "slack_channels"
    t.string "check_type"
    t.text "message"
    t.datetime "last_run_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_checks_on_creator_id"
    t.index ["query_id"], name: "index_blazer_checks_on_query_id"
  end

  create_table "blazer_dashboard_queries", force: :cascade do |t|
    t.bigint "dashboard_id"
    t.bigint "query_id"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dashboard_id"], name: "index_blazer_dashboard_queries_on_dashboard_id"
    t.index ["query_id"], name: "index_blazer_dashboard_queries_on_query_id"
  end

  create_table "blazer_dashboards", force: :cascade do |t|
    t.bigint "creator_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_dashboards_on_creator_id"
  end

  create_table "blazer_queries", force: :cascade do |t|
    t.bigint "creator_id"
    t.string "name"
    t.text "description"
    t.text "statement"
    t.string "data_source"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_queries_on_creator_id"
  end

  create_table "books", force: :cascade do |t|
    t.string "number"
    t.string "name"
    t.integer "position"
    t.integer "law_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "chapters", force: :cascade do |t|
    t.integer "position"
    t.string "name"
    t.string "number"
    t.integer "law_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "datapoint_types", force: :cascade do |t|
    t.integer "user_permission_id"
    t.string "name"
    t.integer "priority"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false

  end

  create_table "datapoints", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "document_id"
    t.integer "document_tag_id"
    t.integer "status"
    t.text "comments"
    t.boolean "is_active"
    t.datetime "last_verified_at", precision: nil
    t.boolean "is_empty_field"
    t.integer "datapoint_type_id"
  end

  create_table "document_relationships", force: :cascade do |t|
    t.integer "document_1_id"
    t.integer "document_2_id"
    t.string "relationship"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "document_slices", force: :cascade do |t|
    t.integer "document_id"
    t.integer "status"
    t.text "comments"
    t.datetime "last_verified_at", precision: nil
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "document_tags", force: :cascade do |t|
    t.integer "document_id"
    t.integer "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id", "tag_id"], name: "index_document_tags_on_document_id_and_tag_id", unique: true
  end

  create_table "document_types", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "alternative_name", default: ""
  end

  create_table "documents", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.date "publication_date"
    t.string "publication_number"
    t.text "description"
    t.text "short_description"
    t.text "full_text"
    t.integer "start_page"
    t.integer "end_page"
    t.integer "position"
    t.string "issue_id"
    t.integer "document_type_id"
    t.boolean "is_verified"
    t.datetime "verification_dt", precision: nil
    t.string "alternative_issue_id", default: ""
    t.string "internal_id", default: ""
    t.string "status", default: ""
    t.string "hierarchy", default: ""
    t.index ["publication_number"], name: "documents_publication_number_idx"
  end

  create_table "email_subscriptions", force: :cascade do |t|
    t.string "email"
    t.string "security_key"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "issuer_document_tags", force: :cascade do |t|
    t.integer "document_id"
    t.integer "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id", "tag_id"], name: "index_issuer_document_tags_on_document_id_and_tag_id", unique: true
  end

  create_table "issuer_law_tags", force: :cascade do |t|
    t.integer "law_id"
    t.integer "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["law_id", "tag_id"], name: "index_issuer_law_tags_on_law_id_and_tag_id", unique: true
  end

  create_table "judgement_auxiliaries", force: :cascade do |t|
    t.integer "document_id"
    t.string "applicable_laws"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "law_accesses", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "law_modifications", force: :cascade do |t|
    t.integer "law_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "law_tags", force: :cascade do |t|
    t.integer "law_id"
    t.integer "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["law_id", "tag_id"], name: "index_law_tags_on_law_id_and_tag_id", unique: true
  end

  create_table "laws", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "modifications"
    t.string "creation_number"
    t.integer "law_access_id"
    t.string "status", default: ""
    t.string "hierarchy", default: ""
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.bigint "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "revoked_at", precision: nil
    t.string "scopes", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.bigint "resource_owner_id"
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.string "scopes"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "permissions", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sections", force: :cascade do |t|
    t.string "number"
    t.string "name"
    t.integer "position"
    t.integer "law_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "slice_verification_histories", force: :cascade do |t|
    t.integer "document_slice_id"
    t.integer "user_id"
    t.string "selected_status"
    t.text "comments"
    t.datetime "verification_dt", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "subsections", force: :cascade do |t|
    t.string "number"
    t.string "name"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "law_id"
  end

  create_table "tag_types", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.integer "tag_type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "titles", force: :cascade do |t|
    t.integer "position"
    t.string "name"
    t.string "number"
    t.integer "law_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_document_download_trackers", force: :cascade do |t|
    t.string "fingerprint"
    t.integer "downloads"
    t.datetime "period_start", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_notifications_histories", force: :cascade do |t|
    t.integer "user_id"
    t.datetime "mail_sent_at", precision: nil
    t.integer "documents_ids", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_permissions", force: :cascade do |t|
    t.integer "user_id"
    t.integer "permission_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_trials", force: :cascade do |t|
    t.integer "user_id"
    t.datetime "trial_start", precision: nil
    t.datetime "trial_end", precision: nil
    t.integer "downloads", default: 0
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "occupation"
    t.boolean "is_contributor"
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.boolean "receive_information_emails"
    t.string "stripe_customer_id"
    t.string "authentication_token", limit: 30
    t.string "unique_session_id"
    t.string "otp_secret"
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login"
    t.string "otp_backup_codes", array: true
    t.text "phone_number", default: ""
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "users_preferences", force: :cascade do |t|
    t.integer "user_id"
    t.string "job_id"
    t.integer "mail_frequency"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_preference_tags", default: [], array: true
    t.boolean "active_notifications", default: true
  end

  create_table "users_preferences_tags", force: :cascade do |t|
    t.integer "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_tag_available"
  end

  create_table "verification_histories", force: :cascade do |t|
    t.integer "datapoint_id"
    t.integer "user_id"
    t.text "comments"
    t.boolean "is_active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "verification_dt", precision: nil
    t.string "selected_status"
  end

  create_table "verifier_user_histories", force: :cascade do |t|
    t.integer "user_id"
    t.integer "verified_data_points"
    t.integer "verification_time"
    t.datetime "verification_dt", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "verification_type"
    t.integer "skipped_elements", default: [], array: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "verification_histories", "datapoints"
  add_foreign_key "verification_histories", "users"
end
