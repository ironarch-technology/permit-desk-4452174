class CreateAccountsAndParcels < ActiveRecord::Migration[7.1]
  def change
    create_table :accounts do |t|
      t.string :email, null: false
      t.string :full_name, null: false
      t.string :role, null: false, default: 'applicant'
      t.string :phone
      t.string :password_digest, null: false
      t.timestamps
    end
    add_index :accounts, :email, unique: true

    create_table :parcels do |t|
      t.string :apn, null: false
      t.string :street_address, null: false
      t.string :city, null: false, default: 'Mountport'
      t.string :postal_code, null: false
      t.string :district, null: false
      t.string :zone_code, null: false
      t.string :owner_name
      t.timestamps
    end
    add_index :parcels, :apn, unique: true
  end
end
