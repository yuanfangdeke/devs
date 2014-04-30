module DEVS
  module Builders
    class AtomicBuilder
      include BaseBuilder

      def initialize(namespace, dsl_type, klass, name=nil, *args, &block)
        if klass.nil? || !klass.respond_to?(:new)
          @model = AtomicModel.new
        else
          @model = klass.new(*args)
        end

        @processor = Simulator.new(@model, namespace)
        @processor.after_initialize if @processor.respond_to?(:after_initialize)

        @model.processor = @processor
        @model.name = name

        case dsl_type
        when :eval then instance_eval(&block)
        when :yield then block.call(self)
        end if block
      end

      def init(&block)
        @model.instance_eval(&block) if block
      end

      # DEVS functions
      def external_transition(&block)
        @model.define_singleton_method(:external_transition, &block) if block
      end
      alias_method :when_input_received, :external_transition

      def internal_transition(&block)
        @model.define_singleton_method(:internal_transition, &block) if block
      end
      alias_method :after_output, :internal_transition

      def confluent_transition(&block)
        @model.define_singleton_method(:confluent_transition, &block) if block
      end
      alias_method :if_transition_collides, :confluent_transition

      def reverse_confluent_transition!
        @model.define_singleton_method(:confluent_transition) do |messages|
          external_transition(messages)
          internal_transition
        end
      end

      def time_advance(&block)
        @model.define_singleton_method(:time_advance, &block) if block
      end

      def output(&block)
        @model.define_singleton_method(:output, &block) if block
      end

      # Hooks
      def post_simulation_hook(&block)
        @model.define_singleton_method(:post_simulation_hook, &block) if block
      end
    end
  end
end
