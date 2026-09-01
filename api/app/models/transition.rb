class Transition < ApplicationRecord
  belongs_to :permit_application

  validates :to_state, :actor, :source_system, :occurred_at, presence: true

  scope :timeline, -> { order(:occurred_at) }
end
