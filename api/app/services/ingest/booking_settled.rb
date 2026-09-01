module Ingest
  # The scheduler confirms or rejects a booking asynchronously once it has taken the
  # slot out of its own capacity pool.
  class BookingSettled
    def call(payload)
      booking = InspectionBooking.find_by(slot_id: payload['slot_id'])
      return if booking.nil?

      booking.update!(
        status: payload['status'],
        scheduled_for: payload['scheduled_for'] && Time.zone.parse(payload['scheduled_for'])
      )
    end
  end
end
