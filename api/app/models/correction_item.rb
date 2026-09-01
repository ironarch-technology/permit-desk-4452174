class CorrectionItem < ApplicationRecord
  belongs_to :permit_application
  has_many :correction_responses, dependent: :destroy

  validates :code, :narrative, :cycle, presence: true

  def latest_response
    correction_responses.order(:responded_at).last
  end

  def answered?
    correction_responses.any?
  end
end
