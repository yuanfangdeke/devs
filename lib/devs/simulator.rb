module DEVS
  module Simulator
    def self.simulate(&block)
      simulation = SimulationBuilder.new(&block).simulation
      simulation.simulate
    end

    class SimulationBuilder
      attr_reader :simulation

      def initialize(&block)
        @simulation = Simulation.new
        instance_eval(&block) if block
      end

      def time(seconds = Simulation::DEFAULT_TIME)
        @simulation.time = seconds
      end

      def models(list = [])
        @simulation.models = list
      end
    end

    class Simulation
      attr_accessor :time
      attr_accessor :models

      DEFAULT_TIME = 60

      def initialize(opts = {})
        opts = {
          time: DEFAULT_TIME,
          models: []
        }.merge(opts)

        @time = opts[:time]
      end
    end
  end
end
