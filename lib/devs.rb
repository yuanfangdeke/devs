require 'logger'
# require 'highline/import'
# require 'graphviz'


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
require 'devs/root_coordinator'

require 'devs/builders'

module DEVS

  # Runs a simulation
  # @todo
  # @example
  #   simulate do
  #     duration = 200
  #
  #   end
  #
  def self.simulate(&block)
    root_coordinator = Builders::SimulationBuilder.new(&block).root_coordinator

    # response = ask("Build the graph of the simulation? (yes, no): ") do |q|
    #   q.default = 'yes'
    #   q.validate = /(yes)|(no)/i
    # end
    # case response
    # when /yes/
    #   GraphBuilder.new(root_coordinator.child.model)
    # end

    root_coordinator.simulate
  end

  # Returns the current version of the gem
  def version
    VERSION
  end
  module_function :version
end
