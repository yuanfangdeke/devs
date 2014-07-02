module DEVS
  module Parallel
    module SimulatorImpl
      def after_initialize
        @bag = []
      end

      def handle_init_event(event)
        @time_last = model.time = event.time
        @time_next = @time_last + model.time_advance
        debug "\t#{model} initialization (time_last: #{@time_last}, time_next: #{@time_next})" if DEVS.logger
      end

      def handle_collect_event(event)
        if event.time == @time_next
          bag = model.fetch_output!
          parent.dispatch(Event.new(:output, event.time, bag)) unless bag.empty?
        else
          raise BadSynchronisationError,
                "time: #{event.time} should match time_next: #{@time_next}"
        end
      end

      def handle_input_event(event)
        @bag.concat(event.bag)
      end

      def handle_internal_event(event)
        synced = (@time_last..@time_next).include?(event.time)

        if event.time == @time_next
          if @bag.empty?
            debug "\tinternal transition: #{model}" if DEVS.logger
            model.internal_transition
          else
            debug "\tconfluent transition: #{model}" if DEVS.logger
            model.confluent_transition(@bag.map { |message|
              ensure_input_message(message)
            })
            @bag.clear
          end
        elsif synced && !@bag.empty?
          debug "\texternal transition: #{model}" if DEVS.logger
          model.elapsed = event.time - @time_last
          model.external_transition(@bag.map { |message|
            ensure_input_message(message)
          })
          @bag.clear
        elsif !synced
          raise BadSynchronisationError, "time: #{event.time} should be between time_last: #{@time_last} and time_next: #{@time_next}"
        end

        @time_last = model.time = event.time
        @time_next = @time_last + model.time_advance
        debug "\t\ttime_last: #{@time_last} | time_next: #{@time_next}" if DEVS.logger
      end
    end
  end
end
