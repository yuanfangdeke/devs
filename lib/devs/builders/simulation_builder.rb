module DEVS
  module Builders
    class SimulationBuilder < CoupledBuilder
      attr_accessor :duration
      attr_reader :root_coordinator

      def initialize(namespace, &block)
        @model = CoupledModel.new
        @model.name = :RootCoupledModel

        @namespace = namespace
        @processor = Coordinator.new(@model, namespace::CoordinatorStrategy)
        @processor.after_initialize if @processor.respond_to?(:after_initialize)

        @model.processor = @processor

        @duration = RootCoordinator::DEFAULT_DURATION

        instance_eval(&block) if block

        @root_coordinator = RootCoordinator.new(@processor, namespace::RootCoordinatorStrategy, @duration)
        @root_coordinator.after_initialize if @root_coordinator.respond_to?(:after_initialize)

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
