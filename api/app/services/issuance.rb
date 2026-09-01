# Issues the permit once payment has been confirmed by Cashiering.
class Issuance
  VALIDITY = 180.days

  def call(application, reason: 'payment captured')
    number = PermitNumbering.next_number

    application.update!(
      permit_number: number,
      issued_at: Time.zone.now,
      valid_until: Time.zone.now + VALIDITY
    )

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
