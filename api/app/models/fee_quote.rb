class FeeQuote < ApplicationRecord
  belongs_to :permit_application

  validates :quote_reference, :amount_cents, :expires_at, presence: true

  def amount
    amount_cents / 100.0
  end

  def expired?
    expires_at < Time.zone.now
  end
end
