# State transitions for a permit application. `permitted?` describes the graph the
# department signed off on; `apply!` writes the transition and its audit row.
class Lifecycle
  ALLOWED = {
    'draft' => %w[submitted withdrawn],
    'submitted' => %w[zoning_check withdrawn],
    'zoning_check' => %w[plan_review denied zoning_hold withdrawn],
    'zoning_hold' => %w[plan_review denied withdrawn],
    'plan_review' => %w[fees_assessed denied corrections_required withdrawn],
    'corrections_required' => %w[plan_review withdrawn],
    'fees_assessed' => %w[issued withdrawn],
    'issued' => %w[expired],
    'denied' => [],
    'withdrawn' => [],
    'expired' => []
  }.freeze

  def self.permitted?(from, to)
    ALLOWED.fetch(from, []).include?(to)
  end

  def self.apply!(application, to:, actor:, source_system: 'permit-desk', reason: nil)
    from = application.state

    ActiveRecord::Base.transaction do
      application.update!(state: to)
      AuditLog.record(
        application,
        from: from,
        to: to,
        actor: actor,
        source_system: source_system,
        reason: reason
      )
    end

    yield if block_given?

    application
  end
end
