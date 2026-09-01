module Clients
  class ServiceError < StandardError
    attr_reader :status, :body

    def initialize(message, status: nil, body: nil)
      super(message)
      @status = status
      @body = body
    end

    def retryable?
      status.nil? || status >= 500
    end
  end
end
