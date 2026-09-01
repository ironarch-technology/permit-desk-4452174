class ApplicationSerializer
  def initialize(application)
    @application = application
  end

  def summary
    {
      reference: @application.reference,
      state: @application.state,
      work_type: @application.work_type,
      address: @application.parcel&.display_address,
      declared_valuation_cents: @application.declared_valuation_cents,
      submitted_at: @application.submitted_at,
      updated_at: @application.updated_at
    }
  end

  def detail
    summary.merge(
      scope_of_work: @application.scope_of_work,
      applicant_name: @application.applicant_name,
      applicant_email: @application.applicant_email,
      applicant_phone: @application.applicant_phone,
      contractor_license_number: @application.contractor_license_number,
      contractor_license_expires_on: @application.contractor_license_expires_on,
      permit_number: @application.permit_number,
      issued_at: @application.issued_at,
      valid_until: @application.valid_until,
      review_cycle: @application.review_cycle,
      zoning_result: @application.zoning_result,
      timeline: timeline,
      corrections: corrections,
      fee_quote: fee_quote
    )
  end

  def staff_row
    {
      reference: @application.reference,
      state: @application.state,
      applicant_name: @application.applicant_name,
      applicant_email: @application.applicant_email,
      address: @application.parcel&.display_address,
      created_at: @application.created_at
    }
  end

  private

  def timeline
    @application.transitions.timeline.map do |transition|
      {
        from: transition.from_state,
        to: transition.to_state,
        actor: transition.actor,
        source: transition.source_system,
        reason: transition.reason,
        at: transition.occurred_at
      }
    end
  end

  def corrections
    @application.current_correction_items.map do |item|
      {
        id: item.id,
        code: item.code,
        narrative: item.narrative,
        citation: item.citation,
        answered: item.answered?,
        response: item.latest_response&.body
      }
    end
  end

  def fee_quote
    quote = @application.active_fee_quote
    return nil if quote.nil?

    {
      reference: quote.quote_reference,
      amount_cents: quote.amount_cents,
      breakdown: quote.breakdown,
      expires_at: quote.expires_at,
      expired: quote.expired?
    }
  end
end
