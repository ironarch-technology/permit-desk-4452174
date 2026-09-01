module Clients
  # Plan Review Service. Work is queued over the bus; this client covers the reads
  # the portal needs for reviewer metadata.
  class ReviewClient
    def initialize
      settings = Rails.configuration.x.services[:review]
      @http = HttpClient.new(base_url: settings[:base_url], api_key: settings[:api_key])
    end

    def queue_depth
      @http.get('/queue')
    end

    def cycle(reference)
      @http.get("/submissions/#{reference}")
    end
  end
end
