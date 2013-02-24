module DEVS
  module Classic
    module Builders
      class SimulationBuilder < CoupledBuilder
        attr_accessor :duration
        attr_reader :root_coordinator

        def initialize(&block)
          @model = CoupledModel.new
          @model.name = :RootCoupledModel
          @model.parent = self

          @processor = Coordinator.new(@model)
          @model.processor = @processor

          @duration = RootCoordinator::DEFAULT_DURATION

          instance_eval(&block) if block

          @root_coordinator = RootCoordinator.new(@processor, @duration)
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
end
