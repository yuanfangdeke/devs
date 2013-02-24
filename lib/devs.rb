require 'logger'
require 'observer'

module DEVS
  INFINITY = Float::INFINITY
end

require 'devs/version'
require 'devs/errors'
require 'devs/logging'
require 'devs/event'
require 'devs/message'
require 'devs/coupling'
require 'devs/port'

require 'devs/classic'

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
    Classic::Builders::SimulationBuilder.new(&block).root_coordinator.simulate
  end
  module_function :simulate

  # Returns the current version of the gem
  def version
    VERSION
  end
  module_function :version
end
