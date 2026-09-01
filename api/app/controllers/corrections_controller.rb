class CorrectionsController < ApplicationController
  include Authentication

  def show
    application = find_own
    render json: {
      reference: application.reference,
      cycle: application.review_cycle,
      items: application.current_correction_items.map { |item| serialize(item) }
    }
  end

  def create
    application = find_own

    unless application.state == 'corrections_required'
      return render json: { error: 'no corrections are outstanding' }, status: :conflict
    end

    responses = params[:responses] || []
    if responses.empty?
      return render json: { error: 'a response is required for each outstanding item' },
                    status: :unprocessable_entity
    end

    responses.each do |entry|
      item = application.correction_items.find(entry[:correction_item_id])
      item.correction_responses.create!(
        cycle: application.review_cycle,
        body: entry[:body],
        responded_at: Time.zone.now
      )
    end

    render json: ApplicationSerializer.new(application.reload).detail
  end

  private

  def find_own
    current_account.permit_applications.find_by!(reference: params[:application_id])
  end

  def serialize(item)
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
