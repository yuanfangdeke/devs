require 'set'
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
require 'devs/builders'

require 'devs/classic'

module DEVS
  # Returns the current version of the gem
  def version
    VERSION
  end
  module_function :version
end
