module Zoning
  # Reads the handle for any application still waiting on zoning and applies the
  # result, for the cases where the callback did not arrive.
  class Reconciliation
    def initialize(client: Clients::ZoningClient.new)
      @client = client
    end

    def call
      PermitApplication.awaiting_zoning.where.not(zoning_check_handle: nil).find_each do |application|
        result = @client.result(application.zoning_check_handle)
        next if result['status'] == 'pending'

        Zoning::ApplyResult.new.call(application, result)
      end
    end
  end
end
