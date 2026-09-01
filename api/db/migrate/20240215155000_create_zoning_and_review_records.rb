class CreateZoningAndReviewRecords < ActiveRecord::Migration[7.1]
  def change
    add_column :permit_applications, :zoning_check_handle, :string
    add_column :permit_applications, :zoning_result, :string
    add_column :permit_applications, :zoning_checked_at, :datetime
    add_column :permit_applications, :review_cycle, :integer, null: false, default: 0
    add_index :permit_applications, :zoning_check_handle

    create_table :correction_items do |t|
      t.references :permit_application, null: false, foreign_key: true
      t.integer :cycle, null: false
      t.string :code, null: false
      t.text :narrative, null: false
      t.string :citation
      t.timestamps
    end
    add_index :correction_items, %i[permit_application_id cycle]

    create_table :correction_responses do |t|
      t.references :correction_item, null: false, foreign_key: true
      t.integer :cycle, null: false
      t.text :body, null: false
      t.datetime :responded_at, null: false
      t.timestamps
    end
  end
end
