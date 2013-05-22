module Looper
  def queue
    @queue ||= Queue.new
  end

  def running?
    @run || false
  end

  def loop
    @run = true

    @thread = Thread.new do
      while @run
        what, *args = *@queue.pop # might block

        name = "handle_#{what}".to_sym
        self.__send__(name, *args) if respond_to?(name)
      end
    end
  end

  def stop
    @run = false
  end

  def post(what, *args)
    @queue << [what, *args]
  end
end
