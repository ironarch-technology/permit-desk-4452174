module Clients
  class SlotTakenError < ServiceError; end

  # Inspection Scheduler. Slot search is a synchronous read against contended
  # capacity, so a search result can be stale by the time a booking is attempted.
  class SchedulingClient
    def initialize
      settings = Rails.configuration.x.services[:scheduling]
      @http = HttpClient.new(base_url: settings[:base_url], api_key: settings[:api_key])
      @district_default = settings[:district_default]
    end

    def slots(inspection_type:, district: nil)
      @http.get('/slots', {
        inspection_type: inspection_type,
        district: district.presence || @district_default
      })
    end

    def book(slot_id:, reference:, inspection_type:)
      @http.post('/bookings', {
        slot_id: slot_id,
        reference: reference,
        inspection_type: inspection_type
      })
    rescue ServiceError => e
      raise SlotTakenError.new('slot no longer available', status: 409, body: e.body) if e.status == 409

      raise
    end
  end
end
