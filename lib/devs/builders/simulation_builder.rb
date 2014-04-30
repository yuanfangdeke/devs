module DEVS
  module Builders
    class SimulationBuilder < CoupledBuilder
      attr_accessor :duration
      attr_reader :root_coordinator

      def initialize(namespace, dsl_type, &block)
        @namespace = namespace
        @dsl_type = dsl_type

        @model = CoupledModel.new
        @model.name = :RootCoupledModel

        @processor = Coordinator.new(@model, namespace)
        @processor.after_initialize if @processor.respond_to?(:after_initialize)

        @model.processor = @processor

        @duration = RootCoordinator::DEFAULT_DURATION

        case dsl_type
        when :eval then instance_eval(&block)
        when :yield then block.call(self)
        end

        @root_coordinator = RootCoordinator.new(@processor, namespace::RootCoordinatorStrategy, @duration)

        hooks.each { |observer| @root_coordinator.add_observer(observer) }
      end

      def duration(duration)
        @duration = duration
      end

      def hooks(observers = [], model = @model)
        if model.is_a? CoupledModel
          model.each { |child| hooks(observers, child) }
        else
          observers << model if model.observer?
        end
        observers
      end
    end
  end
end
