class InspectionsController < ApplicationController
  include Authentication

  def index
    application = find_own
    return render json: { error: 'permit is not issued' }, status: :conflict unless application.state == 'issued'

    slots = Clients::SchedulingClient.new.slots(
      inspection_type: params[:inspection_type],
      district: application.parcel&.district
    )

    render json: slots
  end

  def create
    application = find_own
    return render json: { error: 'permit is not issued' }, status: :conflict unless application.state == 'issued'

    client = Clients::SchedulingClient.new
    booking = client.book(
      slot_id: params[:slot_id],
      reference: application.reference,
      inspection_type: params[:inspection_type]
    )

    record = application.inspection_bookings.create!(
      slot_id: params[:slot_id],
      inspection_type: params[:inspection_type],
      district: application.parcel&.district,
      status: booking['status'] || 'requested',
      scheduled_for: booking['scheduled_for'] && Time.zone.parse(booking['scheduled_for'])
    )

    render json: { booking: serialize(record) }, status: :created
  rescue Clients::SlotTakenError
    alternatives = Clients::SchedulingClient.new.slots(
      inspection_type: params[:inspection_type],
      district: application.parcel&.district
    )

    render json: {
      status: 'slot_unavailable',
      message: 'That appointment was taken while you were choosing. Pick another below.',
      alternatives: alternatives['slots'] || []
    }, status: :ok
  end

  private

  def find_own
    current_account.permit_applications.find_by!(reference: params[:application_id])
  end

  def serialize(record)
    {
      id: record.id,
      slot_id: record.slot_id,
      inspection_type: record.inspection_type,
      status: record.status,
      scheduled_for: record.scheduled_for
    }
  end
end
