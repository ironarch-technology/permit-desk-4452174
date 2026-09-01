module Maintenance
  # Drafts abandoned before submission clutter the applicant's dashboard and the
  # counter's reporting, so anything untouched for a year is dropped.
  class DraftSweep
    RETENTION = 365.days

    def call
      stale = PermitApplication.where(state: 'draft').where('updated_at < ?', RETENTION.ago)
      count = stale.count
      return if count.zero?

      stale.destroy_all
      Rails.logger.info("maintenance.draft_sweep removed=#{count}")
    end
  end
end
