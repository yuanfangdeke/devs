module DEVS
  module Notifications
    def self.notifier
      @notifier ||= Fanout.new
    end

    def publish(pattern, *args)
      Notifications.notifier.publish(pattern, *args)
    end

    def subscribe(*args)
      Notifications.notifier.subscribe(*args)
    end

    def unsubscribe(*args)
      Notifications.notifier.unsubscribe(*args)
    end

    class Fanout
      def initialize
        @subscribers = []
        @listeners_for = {}
      end

      def subscribe(instance, pattern, method = :update)
        subscriber = Subscriber.new(instance, pattern, method).tap do |s|
          @subscribers << s
        end
        @listeners_for.clear
        subscriber
      end

      def unsubscribe(instance, pattern = nil)
        @subscribers.reject! { |s| s.matches?(subscriber) }
        @listeners_for.clear
      end

      def publish(pattern, *args)
        listeners_for(pattern).each { |s| s.publish(pattern, *args) }
      end

      def listeners_for(pattern)
        @listeners_for[pattern] ||= @subscribers.select { |s| s.subscribed_to?(pattern) }
      end

      def listening?(pattern)
        listeners_for(pattern).any?
      end
    end

    class Subscriber
      attr_reader :instance, :pattern, :method

      def initialize(instance, pattern, method)
        @instance = instance
        @pattern = pattern
        @method = method
      end

      def publish(pattern, *args)
        @instance.send @method, pattern, *args
      end

      def subscribed_to?(pattern)
        !pattern || @pattern === pattern.to_s
      end

      def matches?(subscriber_or_pattern)
        self === subscriber_or_pattern ||
          @pattern && @pattern === subscriber_or_pattern
      end
    end
  end
end
