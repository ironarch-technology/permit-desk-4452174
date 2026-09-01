class InspectionBooking < ApplicationRecord
  belongs_to :permit_application

  STATUSES = %w[requested confirmed rejected].freeze

  validates :slot_id, :inspection_type, presence: true
  validates :status, inclusion: { in: STATUSES }
end
