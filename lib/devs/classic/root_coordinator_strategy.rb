module DEVS
  module Classic
    module RootCoordinatorStrategy
      def run(rc)
        rc.child.dispatch(Event.new(:init, rc.time))
        rc.time = rc.child.time_next

        loop do
          rc.send :debug, "* Tick at: #{rc.time}, #{Time.now - rc.start_time} secs elapsed" if DEVS.logger
          rc.child.dispatch(Event.new(:internal, rc.time))
          rc.time = rc.child.time_next
          break if rc.time >= rc.duration
        end
      end
      module_function :run
    end
  end
end
