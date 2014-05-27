module DEVS
  module Parallel
    module RootCoordinatorStrategy
      def run(rc)
        rc.child.dispatch(Event.new(:init, rc.time))
        rc.time = rc.child.time_next

        loop do
          rc.send :debug, "* Tick at: #{rc.time}, #{Time.now - rc.start_time} secs elapsed"
          rc.child.dispatch(Event.new(:collect, rc.time))
          rc.child.dispatch(Event.new(:internal, rc.time))
          rc.time = rc.child.time_next
          break if rc.time >= rc.duration
        end
      end
      module_function :run
    end
  end
end
