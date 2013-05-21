module DEVS
  module Builders
    class AtomicBuilder
      attr_reader :model, :processor

      def initialize(namespace, klass, *args, &block)
        if klass.nil? || !klass.respond_to?(:new)
          @model = AtomicModel.new
        else
          @model = klass.new(*args)
        end

        @processor = Simulator.new(@model)
        @processor.singleton_class.send(:include, namespace::DispatchTemplate)
        @processor.singleton_class.send(:include, namespace::SimulatorStrategy)
        @processor.after_initialize if @processor.respond_to?(:after_initialize)

        @model.processor = @processor
        instance_eval(&block) if block
      end

      def add_input_port(*args)
        @model.add_input_port(*args)
      end

      def add_output_port(*args)
        @model.add_output_port(*args)
      end

      def name(name)
        @model.name = name
      end

      def init(&block)
        @model.instance_eval(&block) if block
      end

      # DEVS functions
      def external_transition(&block)
        @model.define_singleton_method(:external_transition, &block) if block
      end

      def internal_transition(&block)
        @model.define_singleton_method(:internal_transition, &block) if block
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
