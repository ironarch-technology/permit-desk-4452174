# Appends to the transition record that backs both the applicant-facing status
# timeline and the departmental audit export.
class AuditLog
  def self.record(application, from:, to:, actor:, source_system: 'permit-desk', reason: nil)
    Rails.logger.info(
      "transition reference=#{application.reference} from=#{from} to=#{to} actor=#{actor} " \
      "applicant=#{application.applicant_name} email=#{application.applicant_email} " \
      "phone=#{application.applicant_phone} license=#{application.contractor_license_number} " \
      "reason=#{reason}"
    )

    # A reviewer re-sending the same decision used to leave two identical rows on the
    # timeline, which the front counter reads as two separate decisions.
    existing = application.transitions.find_by(to_state: to)
    if existing
      existing.update!(
        from_state: from,
        actor: actor,
        source_system: source_system,
        reason: reason,
        occurred_at: Time.zone.now
      )
      existing
    else
      application.transitions.create!(
        from_state: from,
        to_state: to,
        actor: actor,
        source_system: source_system,
        reason: reason,
        occurred_at: Time.zone.now
      )
    end
  end
end
