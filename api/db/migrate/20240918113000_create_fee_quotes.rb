class CreateFeeQuotes < ActiveRecord::Migration[7.1]
  def change
    create_table :fee_quotes do |t|
      t.references :permit_application, null: false, foreign_key: true
      t.string :quote_reference, null: false
      t.bigint :amount_cents, null: false
      t.jsonb :breakdown, null: false, default: {}
      t.datetime :expires_at, null: false
      t.datetime :superseded_at
      t.timestamps
    end
    add_index :fee_quotes, :quote_reference, unique: true
  end
end
