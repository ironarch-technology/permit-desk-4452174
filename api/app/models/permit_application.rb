class PermitApplication < ApplicationRecord
  STATES = %w[
    draft submitted zoning_check zoning_hold plan_review corrections_required
    fees_assessed issued denied withdrawn expired
  ].freeze

  TERMINAL_STATES = %w[denied withdrawn expired].freeze

  WORK_TYPES = {
    'residential_addition' => { min_cents: 100_00, max_cents: 2_500_000_00 },
    'residential_alteration' => { min_cents: 100_00, max_cents: 750_000_00 },
    'commercial_tenant_improvement' => { min_cents: 500_00, max_cents: 10_000_000_00 },
    'reroof' => { min_cents: 100_00, max_cents: 150_000_00 },
    'solar_photovoltaic' => { min_cents: 100_00, max_cents: 500_000_00 },
    'demolition' => { min_cents: 100_00, max_cents: 1_000_000_00 }
  }.freeze

  belongs_to :account
  belongs_to :parcel, optional: true

  has_many :transitions, -> { order(:occurred_at) }, dependent: :destroy
  has_many :correction_items, dependent: :destroy
  has_many :fee_quotes, dependent: :destroy
  has_many :inspection_bookings, dependent: :destroy

  before_validation :assign_reference, on: :create

  validates :reference, presence: true, uniqueness: true
  validates :work_type, inclusion: { in: WORK_TYPES.keys }, allow_blank: true

  scope :awaiting_zoning, -> { where(state: 'zoning_check') }

  def terminal?
    TERMINAL_STATES.include?(state)
  end

  def submitted?
    !%w[draft].include?(state)
  end

  def current_correction_items
    correction_items.where(cycle: review_cycle).order(:code)
  end

  def active_fee_quote
    fee_quotes.where(superseded_at: nil).order(:created_at).last
  end

  def contact_summary
    "#{applicant_name} <#{applicant_email}>"
  end

  private

  def assign_reference
    self.reference ||= begin
      suffix = SecureRandom.alphanumeric(6).upcase
      "PA-#{Time.current.year}-#{suffix}"
    end
  end
end
