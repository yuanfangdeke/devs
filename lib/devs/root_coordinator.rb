module DEVS
  # This class represent the processor on top of the simulation tree,
  # responsible for coordinating the simulation
  class RootCoordinator
    # used for hooks
    include Observable
    include Logging

    attr_accessor :duration

    # The default duration of the simulation if argument omitted
    DEFAULT_DURATION = 60

    attr_reader :time, :duration, :start_time, :final_time

    # @!attribute [r] time
    #   @return [Numeric] Returns the current simulation time

    # @!attribute [r] start_time
    #   @return [Time] Returns the time at which the simulation started

    # @!attribute [r] duration
    #   @return [Numeric] Returns the total duration of the simulation time

    # Returns a new {RootCoordinator} instance.
    #
    # @param child [Coordinator] the child coordinator
    # @param namespace [Module] the namespace providing template method
    #   implementation
    # @param duration [Numeric] the duration of the simulation
    # @raise [ArgumentError] if the child is not a coordinator
    def initialize(child, namespace, duration = DEFAULT_DURATION)
      unless child.is_a?(Coordinator)
        raise ArgumentError, 'child must be of Coordinator type'
      end
      extend namespace::RootCoordinatorImpl
      @duration = duration
      @time = 0
      @child = child
      @lock = Mutex.new
    end

    def time
      @lock.synchronize { @time }
    end
    alias_method :clock, :time

    def duration=(v)
      @duration = v if waiting?
    end

    def start_time
      @lock.synchronize { @start_time }
    end

    def final_time
      @lock.synchronize { @final_time }
    end

    # Returns <tt>true</tt> if the simulation is done, <tt>false</tt> otherwise.
    #
    # @return [Boolean]
    def done?
      @lock.synchronize { @time >= @duration }
    end

    # Returns <tt>true</tt> if the simulation is currently running,
    #   <tt>false</tt> otherwise.
    #
    # @return [Boolean]
    def running?
      @lock.synchronize { defined?(@start_time) } && !done?
    end

    # Returns <tt>true</tt> if the simulation is waiting to be started,
    #   <tt>false</tt> otherwise.
    #
    # @return [Boolean]
    def waiting?
      @lock.synchronize { !defined?(@start_time) }
    end

    # Returns the simulation status: <tt>waiting</tt>, <tt>running</tt> or
    #   <tt>done</tt>.
    #
    # @return [Symbol] the simulation status
    def status
      if waiting?
        :waiting
      elsif running?
        :running
      elsif done?
        :done
      end
    end

    def percentage
      case status
      when :waiting then 0.0 * 100
      when :done    then 1.0 * 100
      when :running
        @lock.synchronize do
          if @time > @duration
            1.0 * 100
          else
            @time.to_f / @duration.to_f * 100
          end
        end
      end
    end

    def elapsed_secs
      case status
      when :waiting
        0.0
      when :done
        @final_time - @start_time
      when :running
        Time.now - @start_time
      end
    end

    # Returns the number of messages per model along with the total
    #
    # @return [Hash<Symbol, Fixnum>]
    def stats
      if done?
        stats = @child.stats
        total = Hash.new(0)
        stats.values.each { |h| h.each { |k, v| total[k] += v }}
        stats[:TOTAL] = total
        stats
      end
    end

    # Wait the simulation to finish
    def wait
      @thread.join
    end

    # Run the simulation in a new thread
    def simulate
      if waiting?
        @thread = Thread.new do
          @lock.synchronize do
            @start_time = Time.now
            info "*** Beginning simulation at #{@start_time} with duration: #{@duration}"
          end

          run     # implemented in RootCoordinatorImpl

          final_time = Time.now
          @lock.synchronize { @final_time = final_time }
          info "*** Simulation ended at #{final_time} after #{elapsed_secs} secs."

          info "* Events stats : {"
          stats.each { |k, v| info "    #{k} => #{v}" }
          info "* }"

          info "* Calling post simulation hooks"
          changed
          notify_observers(:post_simulation)
        end
      else
        if running?
          error "The simulation already started at #{@start_time} and is currently running."
        else
          error "The simulation is already done. Started at #{@start_time} and finished at #{@final_time} in #{elapsed_secs} secs."
        end

        nil
      end

      self
    end

    private
    attr_writer :time

    def time=(v)
      @lock.synchronize { @time = v }
    end
  end
end
