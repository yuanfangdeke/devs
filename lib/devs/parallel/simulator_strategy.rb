module DEVS
  module Parallel
    module SimulatorStrategy
      def after_initialize
        @bag = []
        @lock = Mutex.new
      end

      def handle_init_event(event)
        @time_last = model.time = event.time
        @time_next = @time_last + model.time_advance
        debug "    time_last: #{@time_last} | time_next: #{@time_next}"
      end

      def handle_collect_event(event)
        if event.time == @time_next
          model.fetch_output! do |message|
            debug "    sent #{message}"
            parent.dispatch(Event.new(:output, event.time, message))
          end
        else
          raise BadSynchronisationError,
                "time: #{event.time} should match time_next: #{@time_next}"
        end
      end

      def handle_input_event(event)
        debug "    adding #{event.message} to bag"
        @bag << event.message
      end

      def handle_internal_event(event)
        if event.time == @time_next
          if @bag.empty?
            debug "   internal transition"
            model.internal_transition
          else
            debug "   confluent transition"
            model.confluent_transition(*frozen_bag)
            @bag.clear
          end
        elsif (@time_last..@time_next).include?(event.time) && !@bag.empty?
          debug "    external transition"
          model.elapsed = event.time - @time_last
          model.external_transition(*frozen_bag)
          @bag.clear
        elsif !(@time_last..@time_next).include?(event.time)
          raise BadSynchronisationError, "time: #{event.time} should be between time_last: #{@time_last} and time_next: #{@time_next}"
        end
        @time_last = model.time = event.time
        @time_next = event.time + model.time_advance
        debug "#{self.model} time_last: #{@time_last} | time_next: #{@time_next}"
      end

      def frozen_bag
        @bag.map { |message| ensure_input_message(message).freeze }
      end
      protected :frozen_bag

      # version bouquin zeigler

      # def handle_internal_event(event)
      #   if event.time == @time_next
      #     model.fetch_output! do |message|
      #       parent.dispatch(Event.new(:y, event.time, message))
      #     end
      #     #:done
      #   else
      #     raise BadSynchronisationError,
      #           "time: #{event.time} should match time_next: #{@time_next}"
      #   end
      # end

      # def handle_input_event(event)
      #   if event.time == @time_next
      #     if @bag.empty?
      #       model.internal_transition
      #     else
      #       model.add_bag(@bag)
      #       model.confluent_transition
      #       @bag.clear
      #     end
      #   elsif (@time_last..@time_next).include?(event.time) && !@bag.empty?
      #     model.elapsed = event.time - @time_last
      #     model.add_bag(@bag)
      #     model.external_transition
      #     @bag.clear

      #     @time_last = model.time = event.time
      #     @time_next = event.time + model.time_advance
      #   elsif !(@time_last..@time_next).include?(event.time)
      #     raise BadSynchronisationError, "time: #{event.time} should be " \
      #         + "between time_last: #{@time_last} and time_next: #{@time_next}"
      #   end
      #   #:done
      # end
    end
  end
end
