module Bus
  # Long-running consumer for the topics the city services publish back to us.
  # Runs in the bus-worker process; see bin/bus_worker.
  class ConsumerGroup
    HANDLERS = {
      Topics::REVIEW_DECISIONS => 'Ingest::ReviewDecision',
      Topics::BOOKING_RESULTS  => 'Ingest::BookingSettled'
    }.freeze

    def initialize
      @consumer = Rdkafka::Config.new(
        :"bootstrap.servers" => settings[:brokers],
        :"group.id" => settings[:consumer_group],
        :"client.id" => "#{settings[:client_id]}-worker",
        :"auto.offset.reset" => 'earliest',
        :"enable.auto.commit" => true,
        :"auto.commit.interval.ms" => 5_000
      ).consumer
    end

    def run
      @consumer.subscribe(*Topics::CONSUMED)
      Rails.logger.info("bus.subscribe topics=#{Topics::CONSUMED.join(',')}")

      @consumer.each do |message|
        process(message)
      end
    end

    private

    def process(message)
      handler = HANDLERS[message.topic]
      return unless handler

      payload = JSON.parse(message.payload)
      handler.constantize.new.call(payload)
    rescue StandardError => e
      Rails.logger.error("bus.consume topic=#{message.topic} error=#{e.class}: #{e.message}")
      sleep 2
      retry
    end

    def settings
      Rails.configuration.x.services[:bus]
    end
  end
end
