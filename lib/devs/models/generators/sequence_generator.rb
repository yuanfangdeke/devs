module DEVS
  module Models
    module Generators
      class SequenceGenerator < DEVS::AtomicModel
        def initialize(min = 1, max = 10, step = 1)
          super()

          add_output_port :value

          @value = min
          @max = max
          @step = step

          @sigma = 1
        end

        def output
          post @value, :value
        end

        def internal_transition
          @value += @step
          @sigma = if @value >= @max
            DEVS::INFINITY
          else
            @step
          end
        end

        def time_advance
          @sigma
        end
      end
    end
  end
end
