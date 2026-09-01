# Issues the permit once payment has been confirmed by Cashiering.
class Issuance
  VALIDITY = 180.days

  def call(application, reason: 'payment captured')
    attempts = 0

    begin
      application.update!(
        permit_number: PermitNumbering.next_number,
        issued_at: Time.zone.now,
        valid_until: Time.zone.now + VALIDITY
      )
    rescue ActiveRecord::RecordNotUnique
      attempts += 1
      raise if attempts >= 5

      retry
    end

    Lifecycle.apply!(
      application,
      to: 'issued',
      actor: 'cashiering-service',
      source_system: 'cashiering',
      reason: reason
    )

    application
  end
end
