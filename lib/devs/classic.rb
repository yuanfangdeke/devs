require 'devs/classic/model'
require 'devs/classic/atomic_model'
require 'devs/classic/coupled_model'
require 'devs/classic/processor'
require 'devs/classic/simulator'
require 'devs/classic/coordinator'
require 'devs/classic/root_coordinator'

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
