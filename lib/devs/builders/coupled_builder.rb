module DEVS
  module Builders
    class CoupledBuilder < AtomicBuilder
      undef :external_transition
      undef :internal_transition
      undef :time_advance
      undef :output
      undef :post_simulation_hook

      def initialize(namespace, klass, *args, &block)
        if klass.nil? || !klass.respond_to?(:new)
          @model = CoupledModel.new
        else
          @model = klass.new(*args)
        end

        @namespace = namespace
        @processor = Coordinator.new(@model)
        @processor.singleton_class.send(:include, namespace::CoordinatorStrategy)
        @processor.after_initialize if @processor.respond_to?(:after_initialize)

        @model.processor = @processor
        instance_eval(&block) if block
      end
      
      # @return [CoupledModel] the new coupled model
      def coupled(*args, &block)
        type = nil
        type, *args = *args if args.first != nil && args.first.respond_to?(:new)

        coordinator = CoupledBuilder.new(@namespace, type, *args, &block).processor
        coordinator.parent = @processor
        coordinator.model.parent = @model
        @model << coordinator.model
        @processor << coordinator
        
        coordinator.model
      end
      
      # @return [AtomicModel] the new atomic model
      def atomic(*args, &block)
        type = nil
        type, *args = *args if args.first != nil && args.first.respond_to?(:new)

        simulator = AtomicBuilder.new(@namespace, type, *args, &block).processor
        simulator.parent = @processor
        simulator.model.parent = @model
        @model << simulator.model
        @processor << simulator
        
        simulator.model
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
      alias_method :add_output_coupling, :add_external_output_coupling

      def add_external_input_coupling(*args)
        @model.add_external_input_coupling(*args)
      end
      alias_method :add_input_coupling, :add_external_input_coupling
    end
  end
end
