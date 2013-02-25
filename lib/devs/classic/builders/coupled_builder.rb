module DEVS
  module Classic
    module Builders
      class CoupledBuilder < AtomicBuilder
        undef :external_transition
        undef :ext_transition
        undef :delta_ext
        undef :internal_transition
        undef :int_transition
        undef :delta_int
        undef :time_advance
        undef :output
        undef :lambda
        undef :post_simulation_hook

        def initialize(klass, *args, &block)
          if klass.nil? || !klass.respond_to?(:new)
            @model = CoupledModel.new
          else
            @model = klass.new(*args)
          end

          @processor = Coordinator.new(@model)
          @model.processor = @processor
          instance_eval(&block) if block
        end

        def coupled(*args, &block)
          type = nil
          type, *args = *args if args.first != nil && args.first.respond_to?(:new)

          coordinator = CoupledBuilder.new(type, *args, &block).processor
          coordinator.parent = @processor
          coordinator.model.parent = @model
          @model << coordinator.model
          @processor << coordinator
        end

        def atomic(*args, &block)
          type = nil
          type, *args = *args if args.first != nil && args.first.respond_to?(:new)

          simulator = AtomicBuilder.new(type, *args, &block).processor
          simulator.parent = @processor
          simulator.model.parent = @model
          @model << simulator.model
          @processor << simulator
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
end
