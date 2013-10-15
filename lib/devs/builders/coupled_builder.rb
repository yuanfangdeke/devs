module DEVS
  module Builders
    class CoupledBuilder < BaseBuilder
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
      alias_method :nest, :coupled

      # @return [AtomicModel] the new atomic model
      def atomic(type=nil, opts={}, &block)
        simulator = AtomicBuilder.new(@namespace, type, opts[:name], *opts[:with_params], &block).processor
        simulator.parent = @processor
        simulator.model.parent = @model
        @model << simulator.model
        @processor << simulator

        simulator.model
      end
      alias_method :add_model, :atomic

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

      def plug(child, opts={})
        @model.add_internal_coupling(child, opts[:with], opts[:from], opts[:to])
      end

      def plug_output_port(port, opts={})
        # def add_external_output_coupling(child, output_port = nil, child_port = nil)
        @model.add_external_output_coupling(opts[:with_child], port, opts[:and_child_port])
      end

      def plug_input_port(port, opts={})
        @model.add_external_input_coupling(opts[:with_child], port, opts[:and_child_port])
      end
    end
  end
end
