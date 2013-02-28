module DEVS
  module Builders
    class SimulationBuilder < CoupledBuilder
      attr_accessor :duration
      attr_reader :root_coordinator

      def initialize(namespace, &block)
        @model = namespace::CoupledModel.new
        @model.name = :RootCoupledModel
        @namespace = namespace

        @processor = namespace::Coordinator.new(@model)
        @model.processor = @processor

        @duration = namespace::RootCoordinator::DEFAULT_DURATION

        instance_eval(&block) if block

        @root_coordinator = namespace::RootCoordinator.new(@processor, @duration)
        hooks.each { |observer| @root_coordinator.add_observer(observer) }
      end

      def duration(duration)
        @duration = duration
      end

      def hooks(observers = [], model = @model)
        if model.is_a? @namespace::CoupledModel
          model.each { |child| hooks(observers, child) }
        else
          observers << model if model.observer?
        end
        observers
      end
    end
  end
end
