require 'set'
require 'logger'
require 'observer'

# @author Romain Franceschini <franceschini.romain@gmail.com>
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
require 'devs/model'
require 'devs/atomic_model'
require 'devs/coupled_model'
require 'devs/simulator'
require 'devs/coordinator'
require 'devs/root_coordinator'
require 'devs/builders'
require 'devs/thread_pool'
require 'devs/latch'
require 'devs/notifications'

require 'devs/classic'

module DEVS
  # Returns the current version of the gem
  #
  # @return [String] the string representation of the version
  def version
    VERSION
  end
  module_function :version
end
