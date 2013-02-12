module DEVS
  class Simulator < Processor
    #
    #
    # variables:
      # tl // time of last event
      # tn // time of next event
      # s // state of the DEVS atomic model
      # e // elapsed time in the actual state
      # y = (y.value, y.port) // current output of the DEVS atomic model
    # when i–message (i, t) is received at time t
      # tl = t − e
      # tn = tl + ta(s)
    # when ∗–message (∗, t) is received at time t
      # y = λ(s)
      # send y–message (y, t) to parent coordinator
      # s = δint(s)
      # tl = t
      # tn =t+ta(s)
    # when x–message (x, t) is received at time t
      # e = t − tl
      # s = δext(s, e, x) tl = t
      # tn =t+ta(s)
    #
    def receive(event)
      puts "#{self.model.name} (tn: #{@time_next}, tl: #{@time_last}) received \
event at time #{event.time} of type #{event.type}"
      case event.type
      when :i
        @time_last = event.time
        model.time = @time_last
        @time_next = @time_last + model.time_advance
      when :*
        if event.time != @time_next
          raise BadSynchronisationError, "time: #{event.time} should match\
          time_next: #{@time_next}"
        end
        model.output
        model.output_messages.each { |message|
          puts "    sent #{message.payload} on port #{message.port.name}"
          parent.dispatch(Event.new(:y, event.time, message))
        }
        model.internal_transition
        @time_last = event.time
        model.time = @time_last
        @time_next = event.time + model.time_advance
      when :x
        unless @time_last <= event.time && event.time <= @time_next
          raise BadSynchronisationError, "time: #{event.time} should be between\
 time_last: #{@time_last} and time_next: #{@time_next}"
        end
        model.elapsed = event.time - @time_last
        puts "    received #{event.message.payload} on port \
#{event.message.port.name}"
        model.add_input_message(event.message)
        model.external_transition
        @time_last = event.time
        model.time = @time_last
        @time_next = event.time + model.time_advance
      end
    end
    alias_method :dispatch, :receive
  end
end
