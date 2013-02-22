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
        end

        def duration(duration)
          @duration = duration
        end
      end
    end
  end
end
