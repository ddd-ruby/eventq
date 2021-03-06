module EventQ
  module Amazon
    class QueueClient

      def initialize(options = {})
        if options.has_key?(:aws_key)
          Aws.config[:credentials] = Aws::Credentials.new(options[:aws_key], options[:aws_secret])
        end

        if !options.has_key?(:aws_account_number)
          raise ':aws_account_number option must be specified.'.freeze
        end

        @aws_account = options[:aws_account_number]

        if options.has_key?(:aws_region)
          @aws_region = options[:aws_region]
          Aws.config[:region] = @aws_region
        else
          @aws_region = Aws.config[:region]
        end
      end

      # Returns the AWS SQS Client
      def sqs
        @sqs ||= Aws::SQS::Client.new
      end

      # Returns the AWS SNS Client
      def sns
        @sns ||= Aws::SNS::Client.new
      end

      def get_topic_arn(event_type)
        _event_type = EventQ.create_event_type(event_type)
        return "arn:aws:sns:#{@aws_region}:#{@aws_account}:#{aws_safe_name(_event_type)}"
      end

      def get_queue_arn(queue)
        _queue_name = EventQ.create_queue_name(queue.name)
        return "arn:aws:sqs:#{@aws_region}:#{@aws_account}:#{aws_safe_name(_queue_name)}"
      end

      def create_topic_arn(event_type)
        _event_type = EventQ.create_event_type(event_type)
        response = sns.create_topic(name: aws_safe_name(_event_type))
        return response.topic_arn
      end

      # Returns the URL of the queue. The queue will be created when it does
      #
      # @param queue [EventQ::Queue]
      def get_queue_url(queue)
        _queue_name = EventQ.create_queue_name(queue.name)
        response= sqs.get_queue_url(
                                     queue_name: aws_safe_name(_queue_name),
                                     queue_owner_aws_account_id: @aws_account,
                                   )
        return response.queue_url
      end

      def aws_safe_name(name)
        return name[0..79].gsub(/[^a-zA-Z\d_\-]/,'')
      end

    end
  end
end
