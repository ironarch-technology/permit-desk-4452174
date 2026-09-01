require 'net/http'

module Clients
  # Shared transport for the Development Services integrations. Each client passes its
  # own base URL and API key; everything else about the call shape is the same.
  class HttpClient
    OPEN_TIMEOUT = 2
    READ_TIMEOUT = 10

    def initialize(base_url:, api_key:)
      @base_url = base_url
      @api_key = api_key
    end

    def get(path, query = {})
      uri = build_uri(path, query)
      request = Net::HTTP::Get.new(uri)
      apply_headers(request)
      execute(uri, request)
    end

    def post(path, body)
      uri = build_uri(path)
      request = Net::HTTP::Post.new(uri)
      apply_headers(request)
      request.body = JSON.generate(body)
      execute(uri, request)
    end

    private

    def build_uri(path, query = {})
      uri = URI.join(@base_url, path)
      uri.query = URI.encode_www_form(query) if query.present?
      uri
    end

    def apply_headers(request)
      request['Authorization'] = "Bearer #{@api_key}"
      request['Content-Type'] = 'application/json'
      request['Accept'] = 'application/json'
    end

    def execute(uri, request)
      response = Net::HTTP.start(
        uri.hostname,
        uri.port,
        use_ssl: uri.scheme == 'https',
        open_timeout: OPEN_TIMEOUT,
        read_timeout: READ_TIMEOUT
      ) { |http| http.request(request) }

      status = response.code.to_i
      if status >= 400
        raise ServiceError.new("#{uri.host} returned #{status}", status: status, body: response.body)
      end

      response.body.present? ? JSON.parse(response.body) : {}
    rescue Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout => e
      raise ServiceError.new("#{uri.host} unreachable: #{e.class}")
    end
  end
end
