module DEVS
  class << self
    attr_accessor :logger
  end
  @logger = Logger.new(STDOUT)

  module Logging
    # Send a debug message
    def debug(string)
      DEVS.logger.debug(string) if DEVS.logger
    end

    # Send a info message
    def info(string)
      DEVS.logger.info(string) if DEVS.logger
    end

    # Send a warning message
    def warn(string)
      DEVS.logger.warn(string) if DEVS.logger
    end

    # Send an error message
    def error(string)
      DEVS.logger.error(string) if DEVS.logger
    end

    module_function :debug, :info, :warn, :error
  end
end
