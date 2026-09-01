class PaymentsController < ApplicationController
  include Authentication

  def create
    application = current_account.permit_applications.find_by!(reference: params[:application_id])
    quote = application.active_fee_quote

    return render json: { error: 'no fee quote on this application' }, status: :conflict if quote.nil?

    if quote.expired?
      refreshed = FeeAssessment.new.call(application)
      return render json: { error: 'fee quote had expired', quote: quote_json(refreshed) }, status: :conflict
    end

    payment = Clients::CashieringClient.new.start_payment(
      quote_reference: quote.quote_reference,
      amount_cents: params[:amount_cents]
    )

    render json: { payment_reference: payment['payment_reference'], status: payment['status'] }
  end

  private

  def quote_json(quote)
    {
      reference: quote.quote_reference,
      amount_cents: quote.amount_cents,
      expires_at: quote.expires_at
    }
  end
end
