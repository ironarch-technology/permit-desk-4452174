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

ActiveRecord::Schema[7.1].define(version: 2025_03_04_094500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "email", null: false
    t.string "full_name", null: false
    t.string "role", default: "applicant", null: false
    t.string "phone"
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_accounts_on_email", unique: true
  end

  create_table "correction_items", force: :cascade do |t|
    t.bigint "permit_application_id", null: false
    t.integer "cycle", null: false
    t.string "code", null: false
    t.text "narrative", null: false
    t.string "citation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["permit_application_id", "cycle"], name: "index_correction_items_on_permit_application_id_and_cycle"
    t.index ["permit_application_id"], name: "index_correction_items_on_permit_application_id"
  end

  create_table "correction_responses", force: :cascade do |t|
    t.bigint "correction_item_id", null: false
    t.integer "cycle", null: false
    t.text "body", null: false
    t.datetime "responded_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["correction_item_id"], name: "index_correction_responses_on_correction_item_id"
  end

  create_table "fee_quotes", force: :cascade do |t|
    t.bigint "permit_application_id", null: false
    t.string "quote_reference", null: false
    t.bigint "amount_cents", null: false
    t.jsonb "breakdown", default: {}, null: false
    t.datetime "expires_at", null: false
    t.datetime "superseded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["permit_application_id"], name: "index_fee_quotes_on_permit_application_id"
    t.index ["quote_reference"], name: "index_fee_quotes_on_quote_reference", unique: true
  end

  create_table "inspection_bookings", force: :cascade do |t|
    t.bigint "permit_application_id", null: false
    t.string "slot_id", null: false
    t.string "inspection_type", null: false
    t.string "district"
    t.datetime "scheduled_for"
    t.string "status", default: "requested", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["permit_application_id"], name: "index_inspection_bookings_on_permit_application_id"
  end

  create_table "parcels", force: :cascade do |t|
    t.string "apn", null: false
    t.string "street_address", null: false
    t.string "city", default: "Mountport", null: false
    t.string "postal_code", null: false
    t.string "district", null: false
    t.string "zone_code", null: false
    t.string "owner_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["apn"], name: "index_parcels_on_apn", unique: true
  end

  create_table "permit_applications", force: :cascade do |t|
    t.string "reference", null: false
    t.bigint "account_id", null: false
    t.bigint "parcel_id"
    t.string "state", default: "draft", null: false
    t.string "work_type"
    t.text "scope_of_work"
    t.bigint "declared_valuation_cents"
    t.string "applicant_name"
    t.string "applicant_email"
    t.string "applicant_phone"
    t.string "contractor_license_number"
    t.date "contractor_license_expires_on"
    t.string "submission_key"
    t.datetime "submitted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "zoning_check_handle"
    t.string "zoning_result"
    t.datetime "zoning_checked_at"
    t.integer "review_cycle", default: 0, null: false
    t.string "permit_number"
    t.datetime "issued_at"
    t.datetime "valid_until"
    t.index ["account_id"], name: "index_permit_applications_on_account_id"
    t.index ["parcel_id"], name: "index_permit_applications_on_parcel_id"
    t.index ["permit_number"], name: "index_permit_applications_on_permit_number"
    t.index ["reference"], name: "index_permit_applications_on_reference", unique: true
    t.index ["state"], name: "index_permit_applications_on_state"
    t.index ["submission_key"], name: "index_permit_applications_on_submission_key", unique: true
    t.index ["zoning_check_handle"], name: "index_permit_applications_on_zoning_check_handle"
  end

  create_table "transitions", force: :cascade do |t|
    t.bigint "permit_application_id", null: false
    t.string "from_state"
    t.string "to_state", null: false
    t.string "actor", null: false
    t.string "source_system", default: "permit-desk", null: false
    t.text "reason"
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["permit_application_id", "occurred_at"], name: "index_transitions_on_permit_application_id_and_occurred_at"
    t.index ["permit_application_id"], name: "index_transitions_on_permit_application_id"
  end

  add_foreign_key "correction_items", "permit_applications"
  add_foreign_key "correction_responses", "correction_items"
  add_foreign_key "fee_quotes", "permit_applications"
  add_foreign_key "inspection_bookings", "permit_applications"
  add_foreign_key "permit_applications", "accounts"
  add_foreign_key "permit_applications", "parcels"
  add_foreign_key "transitions", "permit_applications"
end
