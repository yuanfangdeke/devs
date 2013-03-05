require 'devs/parallel/version'
require 'devs/parallel/event'
require 'devs/parallel/atomic_model'
require 'devs/parallel/coupled_model'
require 'devs/parallel/simulator'
require 'devs/parallel/coordinator'
require 'devs/parallel/root_coordinator'

module DEVS
  def psimulate(&block)
    Builders::SimulationBuilder.new(Parallel, &block).root_coordinator.simulate
  end
  module_function :psimulate
end
er.new(Parallel, &block).root_coordinator.simulate
  end
  module_function :psimulate
end
