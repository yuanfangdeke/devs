require 'devs/parallel/atomic_model'
require 'devs/parallel/coupled_model'

require 'devs/parallel/simulator_strategy'
require 'devs/parallel/coordinator_strategy'
require 'devs/parallel/root_coordinator_strategy'

module DEVS
  def simulate(&block)
    Builders::SimulationBuilder.new(Parallel, &block).root_coordinator.simulate
  end
  module_function :simulate
end
