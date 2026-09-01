module Bus
  module Topics
    ZONING_CHECKS_REQUESTED = 'mountport.zoning.checks.requested'.freeze
    REVIEW_SUBMISSIONS      = 'mountport.review.submissions'.freeze
    REVIEW_DECISIONS        = 'mountport.review.decisions'.freeze
    QUOTE_REQUESTS          = 'mountport.cashiering.quotes.requested'.freeze
    QUOTES_ISSUED           = 'mountport.cashiering.quotes.issued'.freeze
    BOOKING_REQUESTS        = 'mountport.scheduling.bookings.requested'.freeze
    BOOKING_RESULTS         = 'mountport.scheduling.bookings.settled'.freeze

    CONSUMED = [REVIEW_DECISIONS, BOOKING_RESULTS].freeze
  end
end
