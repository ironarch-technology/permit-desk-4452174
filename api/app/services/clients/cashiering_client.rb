require 'net/http'

module Clients
  # Cashiering Service. Fee calculation is synchronous against the published fee
  # schedule; payment capture is confirmed on the callback, not here.
  class CashieringClient
    def initialize
      @settings = Rails.configuration.x.services[:cashiering]
    end

    def quote(reference:, work_type:, valuation_cents:, district:)
      post('/quotes', {
        reference: reference,
        work_type: work_type,
        valuation_cents: valuation_cents,
        district: district,
        merchant_id: @settings[:merchant_id]
      })
    end

    def start_payment(quote_reference:, amount_cents:)
      post('/payments', {
        quote_reference: quote_reference,
        amount_cents: amount_cents,
        merchant_id: @settings[:merchant_id]
      })
    end

    private

    def post(path, body)
      uri = URI.join(@settings[:base_url], path)
      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{@settings[:merchant_secret]}"
      request['Content-Type'] = 'application/json'
      request.body = JSON.generate(body)

      response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
      status = response.code.to_i
      if status >= 400
        raise ServiceError.new("cashiering returned #{status}", status: status, body: response.body)
      end

      JSON.parse(response.body)
    end
  end
end
