class CreatePermitApplications < ActiveRecord::Migration[7.1]
  def change
    create_table :permit_applications do |t|
      t.string :reference, null: false
      t.references :account, null: false, foreign_key: true
      t.references :parcel, foreign_key: true
      t.string :state, null: false, default: 'draft'
      t.string :work_type
      t.text :scope_of_work
      t.bigint :declared_valuation_cents
      t.string :applicant_name
      t.string :applicant_email
      t.string :applicant_phone
      t.string :contractor_license_number
      t.date :contractor_license_expires_on
      t.string :submission_key
      t.datetime :submitted_at
      t.timestamps
    end
    add_index :permit_applications, :reference, unique: true
    add_index :permit_applications, :submission_key, unique: true
    add_index :permit_applications, :state
  end
end
