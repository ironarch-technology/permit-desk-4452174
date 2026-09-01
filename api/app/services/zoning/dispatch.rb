module Zoning
  # Submits the zoning check and records the handle the service gives us back.
  class Dispatch
    def initialize(client: Clients::ZoningClient.new)
      @client = client
    end

    def call(application)
      response = @client.submit_check(
        reference: application.reference,
        apn: application.parcel&.apn,
        work_type: application.work_type,
        scope_of_work: application.scope_of_work
      )

      application.update!(zoning_check_handle: response['handle'])

      Bus::Producer.publish(
        Bus::Topics::ZONING_CHECKS_REQUESTED,
        key: application.reference,
        payload: {
          reference: application.reference,
          handle: response['handle'],
          apn: application.parcel&.apn,
          work_type: application.work_type
        }
      )

      response['handle']
    end
  end
end
