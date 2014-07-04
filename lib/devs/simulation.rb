module DEVS
  # This class represent the interface to the simulation
  class Simulation
    include Observable        # used for hooks
    include Logging
    include Enumerable

    attr_reader :duration, :start_time, :final_time, :time, :processor,
                :build_start_time, :build_end_time, :build_elapsed_secs

    # @!attribute [r] time
    #   @return [Numeric] Returns the current simulation time

    # @!attribute [r] start_time
    #   @return [Time] Returns the time at which the simulation started

    # @!attribute [rw] duration
    #   @return [Numeric] Returns the total duration of the simulation time

    # @!attribute [r] init_time
    #   @return [Numeric] Returns the duration of the initialization

    # Returns a new {Simulation} instance.
    #
    # @param child [Coordinator] the child coordinator
    # @param strategy [Module] the strategy responding ro run
    # @param duration [Numeric] the duration of the simulation
    # @raise [ArgumentError] if the child is not a coordinator
    def initialize(processor, duration, build_start_time)
      @duration = duration
      @time = 0
      @processor = processor
      @lock = Mutex.new
      hooks.each { |observer| add_observer(observer) }
      @build_start_time = build_start_time
      @build_end_time = Time.now
      @build_elapsed_secs = @build_end_time - @build_start_time
      info "*** Builded simulation at #{@build_end_time} after #{@build_elapsed_secs} secs." if DEVS.logger
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
        @stats ||= (stats = @processor.stats
          total = Hash.new(0)
          stats.values.each { |h| h.each { |k, v| total[k] += v if v }}
          stats[:TOTAL] = total
          stats
        )
      end
    end

    # Run the simulation in a new thread
    def simulate
      if waiting?
        begin_simulation
        self.time = t = @processor.init(self.time)
        run = true
        while run
          "* Tick at: #{time}, #{Time.now - @start_time} secs elapsed" if DEVS.logger
          self.time = t = @processor.step(t)
          run = false if t >= @duration
        end
        end_simulation
      else
        if running?
          error "The simulation already started at #{@start_time} and is currently running."
        else
          error "The simulation is already done. Started at #{@start_time} and finished at #{@final_time} in #{elapsed_secs} secs."
        end if DEVS.logger
      end
      self
    end

    def each(&block)
      if waiting?
        if block_given?
          begin_simulation
          self.time = t = @processor.init(self.time)
          run = true
          while run
            "* Tick at: #{time}, #{Time.now - @start_time} secs elapsed" if DEVS.logger
            self.time = t = @processor.step(t)
            yield(self, t)
            run = false if t >= @duration
          end
          end_simulation
        else
          return enum_for(:each, &block)
        end
      elsif DEVS.logger
        if running?
          error "The simulation already started at #{@start_time} and is currently running."
        else
          error "The simulation is already done. Started at #{@start_time} and finished at #{@final_time} in #{elapsed_secs} secs."
        end
        nil
      end
    end

    private
    def time=(v)
      @lock.synchronize { @time = v }
    end

    def hooks
      models = Array.new(@processor.model.components)
      observers = []
      index = 0

      while index < models.count
        model = models[index]

        if model.atomic? && model.observer?
          observers << model
        elsif model.coupled?
          models.concat(model.components)
        end

        index += 1
      end

      observers
    end
    private :hooks

    def begin_simulation
      @lock.synchronize do
        @start_time = Time.now
        info "*** Beginning simulation at #{@start_time} with duration: #{@duration}" if DEVS.logger
      end
    end

    def end_simulation
      final_time = Time.now
      @lock.synchronize { @final_time = final_time }

      if DEVS.logger
        info "*** Simulation ended at #{final_time} after #{elapsed_secs} secs."
        debug "* Events stats : {"
        stats.each { |k, v| debug "    #{k} => #{v}" }
        debug "* }"
        debug "* Calling post simulation hooks"
      end

      changed
      notify_observers(:post_simulation)
    end
  end
end
