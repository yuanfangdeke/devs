require 'devs/classic/simulator_impl'
require 'devs/classic/coordinator_impl'
require 'devs/classic/root_coordinator_strategy'

module DEVS
  def simulate(&block)
    Builders::SimulationBuilder.new(Classic, &block).root_coordinator.simulate
  end
  module_function :simulate
end
