module DEVS
  module Parallel
    module CoordinatorImpl
      def after_initialize
        @synchronize = []
        @bag = []
      end

      def handle_init_event(event)
        @children.each { |child| child.dispatch(event) }
        @scheduler = Scheduler.new(@children.select{ |c| c.time_next < DEVS::INFINITY })
        @time_last = max_time_last
        @time_next = min_time_next
        debug "\t#{model} set tl: #{@time_last}; tn: #{@time_next}"
      end

      def handle_collect_event(event)
        if event.time == @time_next
          @time_last = event.time

          imminent_children.each do |child|
            debug "\t#{model} dispatching #{event}"
            child.dispatch(event)
            @synchronize << child
          end
        else
          raise BadSynchronisationError,
                "\ttime: #{event.time} should match time_next: #{@time_next}"
        end
      end

      def handle_output_event(event)
        bag = event.bag
        parent_bag = []
        child_bags = Hash.new { |hsh, key| hsh[key] = [] }

        bag.each do |message|
          payload, port = *message
          source = port.host.processor

          # check internal coupling to get children who receive sub-bag of y
          model.each_internal_coupling(port) do |coupling|
            receiver = coupling.destination.processor
            child_bags[receiver] << Message.new(payload, coupling.destination_port)
            @synchronize << receiver
          end

          # check external coupling to form sub-bag of parent output
          model.each_output_coupling(port) do |coupling|
            parent_bag << Message.new(payload, coupling.destination_port)
          end
        end

        child_bags.each do |receiver, sub_bag|
          unless sub_bag.empty?
            debug "\t#{model} dispatch input #{sub_bag.map{|m|m.payload.to_s + '@' + m.port.to_s}} to #{receiver.model} from output event"
            receiver.dispatch(Event.new(:input, event.time, sub_bag))
          end
        end

        unless parent_bag.empty?
          debug "\t#{model} dispatch output #{parent_bag.map{|m|m.payload.to_s + '@' + m.port.to_s}} to parent"
          parent.dispatch(Event.new(:output, event.time, parent_bag))
        end
      end

      def handle_input_event(event)
        @bag.push(*event.bag)
      end

      def handle_internal_event(event)
        if (@time_last..@time_next).include?(event.time)
          child_bags = Hash.new { |hash, key| hash[key] = [] }
          @bag.each do |message|
            payload, port = *message
            # check external input couplings to get children who receive sub-bag of y
            model.each_input_coupling(port) do |coupling|
              receiver = coupling.destination.processor
              child_bags[receiver] << Message.new(payload, coupling.destination_port)
              @synchronize << receiver
            end
          end

          child_bags.each do |receiver, sub_bag|
            unless sub_bag.empty?
              debug "\t#{model} dispatch input #{sub_bag.map{|m|m.payload.to_s + '@' + m.port.to_s}} to #{receiver.model} from output event"
              receiver.dispatch(Event.new(:input, event.time, sub_bag))
            end
          end
          @bag.clear

          @synchronize.uniq!
          @synchronize.each do |child|
            new_event = Event.new(:internal, event.time)
            debug "\t#{model} dispatching #{new_event}"
            @scheduler.unschedule(child)
            child.dispatch(new_event)
            @scheduler.schedule(child) if child.time_next < DEVS::INFINITY
          end
          @synchronize.clear

          @time_last = event.time
          @time_next = min_time_next
          debug "\t#{model} time_last: #{@time_last} | time_next: #{@time_next}"
        else
          raise BadSynchronisationError, "time: #{event.time} should be between time_last: #{@time_last} and time_next: #{@time_next}"
        end
      end
    end
  end
end
