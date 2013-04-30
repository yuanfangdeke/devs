module DEVS
  module Classic
    module RootCoordinatorStrategy
      def simulate(context)
        child.dispatch(Event.new(:i, context.time))
        context.time = context.child.time_next

        loop do
          info "* Tick at: #{context.time}, #{Time.now - context.start_time} secs elapsed"
          child.dispatch(Event.new(:*, context.time))
          context.time = context.child.time_next
          break if context.time >= context.duration
        end
      end
    end
  end
end
