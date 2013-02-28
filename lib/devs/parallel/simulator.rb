module DEVS
  module Parallel
    class Simulator < Classic::Simulator
      #include Celluloid

      def initialize(model)
        super(model)
        @bag = []
      end

      def dispatch(event)
        super(event)

        case event.type
        when :'@' then handle_collect_event(event)
        end
      end

      protected

      def handle_collect_event(event)
        if event.time == @time_next
          model.fetch_output! do |message|
            #parent.async.dispatch(Event.new(:y, event.time, message))
            parent.dispatch(Event.new(:y, event.time, message))
          end
          :done
        else
          raise BadSynchronisationError,
                "time: #{event.time} should match time_next: #{@time_next}"
        end
      end

      def handle_input_event(event)
        @bag << event.message
        :done
      end

      def handle_star_event(event)
        if event.time == @time_next
          if @bag.empty?
            info "  internal transition"
            model.internal_transition
          else
            info "  confluent transition"
            model.add_bag(@bag)
            model.confluent_transition
            @bag.clear
          end
        elsif (@time_last..@time_next).include?(event.time) && !@bag.empty?
          info "  external transition"
          model.elapsed = event.time - @time_last
          model.add_bag(@bag)
          model.external_transition
          @bag.clear
        elsif !(@time_last..@time_next).include?(event.time)
          raise BadSynchronisationError, "time: #{event.time} should be " \
              + "between time_last: #{@time_last} and time_next: #{@time_next}"
        end
        @time_last = model.time = event.time
        @time_next = event.time + model.time_advance
        info "#{self.model} time_last: #{@time_last} | time_next: #{@time_next}"
        :done
      end

      # def handle_star_event(event)
      #   if event.time == @time_next
      #     model.fetch_output! do |message|
      #       parent.dispatch(Event.new(:y, event.time, message))
      #     end
      #     :done
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
      #   elsif !(@time_last..@time_next).include?(event.time)
      #     raise BadSynchronisationError, "time: #{event.time} should be " \
      #         + "between time_last: #{@time_last} and time_next: #{@time_next}"
      #   end
      #   @time_last = model.time = event.time
      #   @time_next = event.time + model.time_advance
      #   :done
      # end
    end
  end
end
