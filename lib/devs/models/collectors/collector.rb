module DEVS
  module Models
    module Collectors
      class Collector < DEVS::AtomicModel
        def initialize
          super()
          @results = {}
        end

        external_transition do |*messages|
          messages.each do |message|
            value, port = *message

            if @results.has_key?(message.port.name)
              ary = @results[port.name]
            else
              ary = []
              @results[port.name] = ary
            end

            ary << [self.time, value] unless value.nil?
          end

          self.sigma = 0
        end

        internal_transition { self.sigma = DEVS::INFINITY }

        time_advance { self.sigma }
      end
    end
  end
end
