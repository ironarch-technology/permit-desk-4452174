module Clients
  # Parcel & Zoning Service. Submission is asynchronous: we get a handle back and the
  # result arrives either on the callback or from a later read of the handle.
  class ZoningClient
    MAX_ATTEMPTS = 3
    BASE_BACKOFF = 0.5

    def initialize
      settings = Rails.configuration.x.services[:zoning]
      @http = HttpClient.new(base_url: settings[:base_url], api_key: settings[:api_key])
    end

    def submit_check(reference:, apn:, work_type:, scope_of_work:)
      with_retries do
        @http.post('/checks', {
          reference: reference,
          apn: apn,
          work_type: work_type,
          scope_of_work: scope_of_work
        })
      end
    end

    def result(handle)
      with_retries { @http.get("/checks/#{handle}") }
    end

    private

    # The zoning index rebuild takes the service down for a few minutes every night,
    # so a submission that lands in that window is worth trying again.
    def with_retries
      attempt = 0
      begin
        attempt += 1
        yield
      rescue ServiceError => e
        raise unless e.retryable? && attempt < MAX_ATTEMPTS

        sleep(BASE_BACKOFF * (2**(attempt - 1)) + rand * 0.25)
        retry
      end
    end
  end
end
