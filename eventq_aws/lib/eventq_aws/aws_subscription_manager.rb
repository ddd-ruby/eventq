module EventQ
  module Amazon
    class SubscriptionManager

      def initialize(options)

        if options[:client] == nil
          raise "[#{self.class}] - :client (QueueClient) must be specified."
        end

        @client = options[:client]

        if options[:queue_manager] == nil
          raise "[#{self.class}] - :queue_manager (QueueManager) must be specified."
        end

        @manager = options[:queue_manager]
      end

      def subscribe(event_type, queue)

        _event_type = EventQ.create_event_type(event_type)
        topic_arn = @client.create_topic_arn(_event_type)

        q = @manager.get_queue(queue)
        queue_arn = @client.get_queue_arn(queue)

        @client.sqs.set_queue_attributes({
                                             queue_url: q,
                                             attributes:{
                                                 'Policy'.freeze => '{
  "Version": "2012-10-17",
  "Id": "SNStoSQS",
  "Statement": [
    {
      "Sid":"rule1",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:*",
      "Resource": "' + queue_arn + '",
      "Condition" : {
        "ArnEquals" : {
          "aws:SourceArn":"' + topic_arn + '"
        }
      }
    }
  ]
}'
                                             }
                                         })

        @client.sns.subscribe({
                                  topic_arn: topic_arn,
                                  protocol: 'sqs'.freeze,
                                  endpoint: queue_arn
                              })

        return true

      end

      def unsubscribe(queue)

        raise "[#{self.class}] - Not implemented. Please unsubscribe the queue from the topic inside the AWS Management Console."

      end

    end
  end
end
