module DEVS
  module Classic
    module RootCoordinatorStrategy
      def run
        child.dispatch(Event.new(:i, @time))
        @time = child.time_next

        loop do
          info "* Tick at: #{@time}, #{Time.now - @start_time} secs elapsed"
          child.dispatch(Event.new(:*, @time))
          @time = child.time_next
          break if @time >= @duration
        end
      end
    end
  end
end
