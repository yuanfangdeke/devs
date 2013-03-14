module DEVS
  module Classic
    class Processor
      include Logging
      attr_accessor :parent
      attr_reader :model, :time_next, :time_last

      def initialize(model)
        @model = model
        @time_next = 0
        @time_last = 0
        @events_count = Hash.new(0)
      end

      def stats
        stats = @events_count.dup
        stats[:total] = stats.values.reduce(&:+)
        info "    #{self.model}: #{stats}"
        @events_count
      end

      def dispatch(event)
        @events_count[event.type] += 1
        info "#{self.model} received #{event}"

        case event.type
        when :i then handle_init_event(event)
        when :* then handle_star_event(event)
        when :x then handle_input_event(event)
        when :y then handle_output_event(event)
        end
      end
    end
  end
end
