require 'set'
require 'logger'
require 'observer'

# @author Romain Franceschini <franceschini.romain@gmail.com>
module DEVS
  INFINITY = Float::INFINITY
end

require 'devs/version'
require 'devs/logging'
require 'devs/errors'
require 'devs/linked_list'
require 'devs/ladder_queue'
require 'devs/event'
require 'devs/message'
require 'devs/coupling'
require 'devs/port'
require 'devs/model'
require 'devs/atomic_model'
require 'devs/coupled_model'
require 'devs/processor'
require 'devs/simulator'
require 'devs/coordinator'
require 'devs/schedulers'
require 'devs/simulation'
require 'devs/builders'
require 'devs/notifications'
require 'devs/parallel'
require 'devs/classic'

module DEVS
  # Builds a simulation
  #
  # @param formalism [Symbol] the formalism to use, either <tt>:pdevs</tt>
  #   for parallel devs (default) or <tt>:devs</tt> for classic devs
  # @example
  #   build do
  #     duration = 200
  #
  #   end
  def build(formalism=:pdevs, dsl_type=:eval, &block)
    namespace = case formalism
    when :pdevs then SequentialParallel
    when :devs then Classic
    end

    builder = Builders::SimulationBuilder.new(namespace, dsl_type, &block)
    builder.simulation
  end
  module_function :build

  def simulate(formalism=:pdevs, dsl_type=:eval, &block)
    build(formalism, dsl_type, &block).simulate
  end
  module_function :simulate

  # Returns the current version of the gem
  #
  # @return [String] the string representation of the version
  def version
    VERSION
  end
  module_function :version
end
