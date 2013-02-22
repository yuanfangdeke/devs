module DEVS
  module Builders
    class CoupledBuilder < AtomicBuilder
      undef :external_transition
      undef :ext_transition
      undef :delta_ext
      undef :internal_transition
      undef :int_transition
      undef :delta_int
      undef :time_advance
      undef :ta
      undef :output
      undef :lambda

      def initialize(klass, *args, &block)
        if klass.nil? || !klass.respond_to?(:new)
          @model = Classic::CoupledModel.new
        else
          @model = klass.new(*args)
        end

        @processor = Classic::Coordinator.new(@model)
        instance_eval(&block) if block
      end

      def coupled(*args, &block)
        type = nil
        type, *args = *args if args.first != nil && args.first.respond_to?(:new)

        coordinator = Classic::CoupledBuilder.new(type, *args, &block).processor
        coordinator.parent = @processor
        coordinator.model.parent = @model
        @model.add_child(coordinator.model)
        @processor.add_child(coordinator)
      end

      def atomic(*args, &block)
        type = nil
        type, *args = *args if args.first != nil && args.first.respond_to?(:new)

        simulator = AtomicBuilder.new(type, *args, &block).processor
        simulator.parent = @processor
        simulator.model.parent = @model
        @model.add_child(simulator.model)
        @processor.add_child(simulator)
      end

      def select(&block)
        @model.define_singleton_method(:select, &block) if block
      end

      def add_internal_coupling(*args)
        @model.add_internal_coupling(*args)
      end

      def add_external_output_coupling(*args)
        @model.add_external_output_coupling(*args)
      end
      alias_method :add_external_output, :add_external_output_coupling

      def add_external_input_coupling(*args)
        @model.add_external_input_coupling(*args)
      end
      alias_method :add_external_input, :add_external_input_coupling
    end
  end
end
