# Requests a fee quote from Cashiering and stores it against the application.
class FeeAssessment
  def initialize(client: Clients::CashieringClient.new)
    @client = client
  end

  def call(application)
    response = @client.quote(
      reference: application.reference,
      work_type: application.work_type,
      valuation_cents: application.declared_valuation_cents,
      district: application.parcel&.district
    )

    application.fee_quotes.where(superseded_at: nil).update_all(superseded_at: Time.zone.now)

    application.fee_quotes.create!(
      quote_reference: response['quote_reference'],
      amount_cents: response['amount_cents'],
      breakdown: response['breakdown'] || {},
      expires_at: Time.zone.parse(response['expires_at'])
    )
  end
end
