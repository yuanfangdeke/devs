require 'devs/classic/simulator_strategy'
require 'devs/classic/coordinator_strategy'

module DEVS
  # Runs a simulation
  # @todo
  # @example
  #   simulate do
  #     duration = 200
  #
  #   end
  #
  def simulate(&block)
    Builders::SimulationBuilder.new(Classic, &block).root_coordinator.simulate
  end
  module_function :simulate
end
