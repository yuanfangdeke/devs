module DEVS
  module SequentialParallel
    module RootCoordinatorStrategy
      def run(rc)
        rc.time = rc.child.init(rc.time)
        run = true
        while run
          rc.send :debug, "* Tick at: #{rc.time}, #{Time.now - rc.start_time} secs elapsed" if DEVS.logger
          rc.time = rc.child.remainder(rc.time, rc.child.collect(rc.time))
          run = false if rc.time >= rc.duration
        end
      end
      module_function :run
    end
  end
end
