class CreateIssuanceAndInspections < ActiveRecord::Migration[7.1]
  def change
    add_column :permit_applications, :permit_number, :string
    add_column :permit_applications, :issued_at, :datetime
    add_column :permit_applications, :valid_until, :datetime
    add_index :permit_applications, :permit_number

    create_table :inspection_bookings do |t|
      t.references :permit_application, null: false, foreign_key: true
      t.string :slot_id, null: false
      t.string :inspection_type, null: false
      t.string :district
      t.datetime :scheduled_for
      t.string :status, null: false, default: 'requested'
      t.timestamps
    end
  end
end
