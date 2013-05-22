module DEVS
  module Parallel
    module RootCoordinatorStrategy
      def run
        child.dispatch(Event.new(:init, @time))
        @time = child.time_next

        loop do
          info "* Tick at: #{@time}, #{Time.now - @start_time} secs elapsed"
          child.dispatch(Event.new(:collect, @time))
          child.dispatch(Event.new(:star, @time))
          @time = child.time_next
          break if @time >= @duration
        end
      end
    end
  end
end
