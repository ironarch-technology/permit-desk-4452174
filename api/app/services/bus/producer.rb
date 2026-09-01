module Bus
  # Thin wrapper over the shared MSK producer. One producer per process; librdkafka
  # batches internally so there is no benefit to holding more than one.
  class Producer
    class << self
      def publish(topic, key:, payload:)
        handle = client.produce(
          topic: topic,
          key: key.to_s,
          payload: JSON.generate(payload),
          headers: {
            'content-type' => 'application/json',
            'source' => 'permit-desk'
          }
        )
        handle.wait(max_wait_timeout: 5)
        Rails.logger.info("bus.publish topic=#{topic} key=#{key}")
        true
      end

      def client
        @client ||= Rdkafka::Config.new(
          :"bootstrap.servers" => settings[:brokers],
          :"client.id" => settings[:client_id],
          :"message.timeout.ms" => 10_000
        ).producer
      end

      def reset!
        @client&.close
        @client = nil
      end

      private

      def settings
        Rails.configuration.x.services[:bus]
      end
    end
  end
end
