module DEVS
  module Parallel
    class AtomicModel < Classic::AtomicModel
      class << self
        def confluent_transition(&block)
          define_method(:confluent_transition, &block) if block
        end
        alias_method :delta_con, :confluent_transition
      end

      # This is the default definition of the confluent transition. Here the
      # internal transition is allowed to occur and this is followed by the
      # effect of the external transition on the resulting state.
      #
      # Override this method to obtain a different behavior. For example, the
      # opposite order of effects (external transition before internal
      # transition). Of course you can override without reference to the other
      # transitions.
      #
      # @todo see elapsed time reset
      def confluent_transition
        internal_transition
        external_transition
      end

      def add_bag(bag)
        inputs = Hash.new { |hash, key| hash[key] = [] }
        bag.each { |msg| inputs[msg.port] << msg.payload }

        inputs.each do |port, values|
          raise InvalidPortHostError if port.host != self
          raise InvalidPortTypeError unless port.input?
          port.incoming = values
        end
      end
    end
  end
end
