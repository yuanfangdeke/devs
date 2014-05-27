module DEVS
  module Parallel
    module SimulatorImpl
      def after_initialize
        @bag = []
      end

      def handle_init_event(event)
        @time_last = model.time = event.time
        @time_next = @time_last + model.time_advance
        debug "\t\t#{model} time_last: #{@time_last} | time_next: #{@time_next}"
      end

      def handle_collect_event(event)
        if event.time == @time_next
          bag = model.fetch_output!
          unless bag.empty?
            debug "\t\t#{model} sends bag #{bag.map{|m|m.payload}}"
            parent.dispatch(Event.new(:output, event.time, bag))
          end
        else
          raise BadSynchronisationError,
                "time: #{event.time} should match time_next: #{@time_next}"
        end
      end

      def handle_input_event(event)
        debug "\t\t#{model} adding #{event.bag.map{|m|m.payload}} to bag"
        @bag.push(*event.bag)
      end

      def handle_internal_event(event)
        synced = (@time_last..@time_next).include?(event.time)

        if event.time == @time_next
          if @bag.empty?
            debug "\t\t#{model} internal transition"
            model.internal_transition
          else
            debug "\t\t#{model} confluent transition"
            model.confluent_transition(frozen_bag)
            @bag.clear
          end
        elsif synced && !@bag.empty?
          debug "\t\t#{model} external transition"
          model.elapsed = event.time - @time_last
          model.external_transition(frozen_bag)
          @bag.clear
        elsif !synced
          raise BadSynchronisationError, "time: #{event.time} should be between time_last: #{@time_last} and time_next: #{@time_next}"
        end

        @time_last = model.time = event.time
        @time_next = @time_last + model.time_advance
        debug "\t\t#{model} time_last: #{@time_last} | time_next: #{@time_next}"
      end

      def frozen_bag
        @bag.map { |message| ensure_input_message(message).freeze }
      end
      protected :frozen_bag
    end
  end
end
