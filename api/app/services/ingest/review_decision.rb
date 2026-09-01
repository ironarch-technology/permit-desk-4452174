module Ingest
  # Plan review publishes a decision per cycle. Correction items arrive with the
  # decision rather than on a separate topic.
  class ReviewDecision
    def call(payload)
      application = PermitApplication.find_by(reference: payload['reference'])
      return if application.nil? || application.terminal?

      case payload['outcome']
      when 'approved'
        approve(application)
      when 'denied'
        deny(application, payload['reason'])
      when 'corrections_required'
        request_corrections(application, payload['items'] || [])
      end
    end

    private

    def approve(application)
      from = application.state
      application.update_column(:state, 'fees_assessed')
      AuditLog.record(
        application,
        from: from,
        to: 'fees_assessed',
        actor: 'plan-reviewer',
        source_system: 'review',
        reason: 'plan review approved'
      )
      FeeAssessment.new.call(application)
    end

    def deny(application, reason)
      from = application.state
      application.update_column(:state, 'denied')
      AuditLog.record(
        application,
        from: from,
        to: 'denied',
        actor: 'plan-reviewer',
        source_system: 'review',
        reason: reason
      )
    end

    def request_corrections(application, items)
      from = application.state
      cycle = application.review_cycle

      items.each do |item|
        application.correction_items.create!(
          cycle: cycle,
          code: item['code'],
          narrative: item['narrative'],
          citation: item['citation']
        )
      end

      application.update_column(:state, 'corrections_required')
      AuditLog.record(
        application,
        from: from,
        to: 'corrections_required',
        actor: 'plan-reviewer',
        source_system: 'review',
        reason: "#{items.length} correction item(s)"
      )
    end
  end
end
