module DEVS
  module Models
    module Generators
      class RandomGenerator < DEVS::AtomicModel
        def initialize(min = 0, max = 10, min_step = 1, max_step = 1, seed = Random.new_seed)
          super()

          @min = min
          @max = max
          @min_step = min_step
          @max_step = max_step
          
          @random = Random.new(seed)
          
          self.sigma = 0
        end

        internal_transition { self.sigma = (@min_step + @random.rand * @max_step).round }

        output do
          messages_count = (1 + @random.rand * output_ports.count).round
          selected_ports = output_ports.sample(messages_count)
          selected_ports.each { |port| post((@min + @random.rand * @max).round, port) }
        end

        time_advance { self.sigma }
      end
    end
  end
end
