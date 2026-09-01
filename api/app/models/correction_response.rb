class CorrectionResponse < ApplicationRecord
  belongs_to :correction_item

  validates :body, :cycle, :responded_at, presence: true

  after_create :return_application_to_review

  private

  # Reviewers asked for the application to move back to their queue as soon as the
  # last outstanding item has an answer, rather than waiting for a nightly sweep.
  def return_application_to_review
    application = correction_item.permit_application
    outstanding = application.current_correction_items.reject(&:answered?)
    return if outstanding.any?

    application.update_column(:state, 'plan_review')
    application.increment!(:review_cycle)
    Bus::Producer.publish(
      Bus::Topics::REVIEW_SUBMISSIONS,
      key: application.reference,
      payload: {
        reference: application.reference,
        cycle: application.review_cycle,
        work_type: application.work_type,
        scope_of_work: application.scope_of_work,
        resubmission: true
      }
    )
  end
end
