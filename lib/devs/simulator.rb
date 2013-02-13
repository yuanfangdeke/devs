module DEVS
  class Simulator < Processor
    def receive(event)
      info "#{self.model.name} (tn: #{@time_next}, tl: #{@time_last}) received \
event at time #{event.time} of type #{event.type}"
      case event.type
      when :i
        @time_last = event.time
        model.time = @time_last
        @time_next = @time_last + model.time_advance
        info "    set tl: #{@time_last}; tn: #{@time_next}"
      when :*
        if event.time != @time_next
          raise BadSynchronisationError, "time: #{event.time} should match\
          time_next: #{@time_next}"
        end
        model.output
        model.output_messages.each { |message|
          info "    sent #{message.payload} on port #{message.port.name}"
          parent.dispatch(Event.new(:y, event.time, message))
        }
        model.internal_transition
        @time_last = event.time
        model.time = @time_last
        @time_next = event.time + model.time_advance
        info "#{self.model.name} set tl: #{@time_last}; tn: #{@time_next}"
      when :x
        unless @time_last <= event.time && event.time <= @time_next
          raise BadSynchronisationError, "time: #{event.time} should be between\
 time_last: #{@time_last} and time_next: #{@time_next}"
        end
        model.elapsed = event.time - @time_last
        info "    received #{event.message.payload} on port \
#{event.message.port.name}"
        model.add_input_message(event.message)
        model.external_transition
        @time_last = event.time
        model.time = @time_last
        @time_next = event.time + model.time_advance
        info "    set tl: #{@time_last}; tn: #{@time_next}"
      end
    end
    alias_method :dispatch, :receive

    def post_simulation_hook
      model.post_simulation_hook
    end
  end
end
