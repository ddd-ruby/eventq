module EventQ
  module RabbitMq
    class SubscriptionManager

      def initialize(options = {})
        if options[:client] == nil
          raise ':client (QueueClient) must be specified.'.freeze
        end
        @client = options[:client]
        @queue_manager = QueueManager.new
        @event_raised_exchange = EventQ::EventRaisedExchange.new
      end

      def subscribe(event_type, queue)

        _event_type = EventQ.create_event_type(event_type)

        connection = @client.get_connection
        channel = connection.create_channel

        queue = @queue_manager.get_queue(channel, queue)
        exchange = @queue_manager.get_exchange(channel, @event_raised_exchange)

        queue.bind(exchange, :routing_key => _event_type)

        channel.close
        connection.close

        EventQ.logger.debug do
          "[#{self.class} #subscribe] - Subscribing queue: #{EventQ.create_queue_name(queue.name)} to Exchange: #{_event_type}"
        end

        return true
      end

      def unsubscribe(queue)

        connection = @client.get_connection
        channel = connection.create_channel

        queue = @queue_manager.get_queue(channel, queue)
        exchange = @queue_manager.get_exchange(channel, @event_raised_exchange)

        queue.unbind(exchange)

        channel.close
        connection.close

        return true
      end

    end
  end
end
