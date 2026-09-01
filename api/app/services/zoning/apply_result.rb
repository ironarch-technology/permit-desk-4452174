module Zoning
  # Turns a zoning outcome into the matching transition.
  class ApplyResult
    OUTCOMES = {
      'permissible' => 'plan_review',
      'not_permissible' => 'denied',
      'indeterminate' => 'zoning_hold'
    }.freeze

    def call(application, result)
      return if application.terminal?

      outcome = result['outcome']
      target = OUTCOMES[outcome]
      return unless target

      application.update!(zoning_result: outcome, zoning_checked_at: Time.zone.now)

      Lifecycle.apply!(
        application,
        to: target,
        actor: 'zoning-service',
        source_system: 'zoning',
        reason: result['reason']
      ) do
        next unless target == 'plan_review'

        Bus::Producer.publish(
          Bus::Topics::REVIEW_SUBMISSIONS,
          key: application.reference,
          payload: {
            reference: application.reference,
            cycle: application.review_cycle,
            work_type: application.work_type,
            scope_of_work: application.scope_of_work,
            valuation_cents: application.declared_valuation_cents
          }
        )
      end
    end
  end
end
