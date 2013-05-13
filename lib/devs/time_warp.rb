require 'devs/time_warp/dispatch_template'
require 'devs/time_warp/simulator_strategy'
require 'devs/time_warp/coordinator_strategy'
require 'devs/time_warp/root_coordinator_strategy'

module DEVS
  def simulate(&block)
    Builders::SimulationBuilder.new(TimeWarp, &block).root_coordinator.simulate
  end
  module_function :simulate
end
