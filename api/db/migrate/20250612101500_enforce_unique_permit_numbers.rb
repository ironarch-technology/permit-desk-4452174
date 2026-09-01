class EnforceUniquePermitNumbers < ActiveRecord::Migration[7.1]
  def change
    remove_index :permit_applications, :permit_number
    add_index :permit_applications, :permit_number, unique: true
  end
end
