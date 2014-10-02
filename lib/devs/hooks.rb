module DEVS
  module Hooks
    def self.notifier
      @notifier ||= Fanout.new
    end

    class Fanout
      def initialize
        @listeners_for = Hash.new { |hash, key| hash[key] = [] }
      end

      def subscribe(hook, instance, method=nil)
        @listeners_for[hook] << Subscriber.new(instance, method || hook)
      end

      def publish(hook, *args)
        @listeners_for[hook].each { |s| s.publish(hook, *args) }
      end
    end

    class Subscriber
      attr_reader :instance, :method

      def initialize(instance, method)
        @instance = instance
        @method = method
      end

      def publish(*args)
        @instance.send(@method, *args)
      end
    end
  end
end
