require 'devs/parallel/simulator_impl'
require 'devs/parallel/coordinator_impl'
require 'devs/parallel/root_coordinator_strategy'

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
    Builders::SimulationBuilder.new(Parallel, &block).root_coordinator.simulate
  end
  module_function :simulate
end
