module DEVS
  module Parallel
    module CoordinatorImpl
      def after_initialize
        @synchronize = Hash.new(false)
        @bag = []
      end

      def handle_init_event(event)
        children = @children
        selected = []
        i = 0
        while i < children.size
          child = children[i]
          child.dispatch(event)
          selected.push(child) if child.time_next < DEVS::INFINITY
          i += 1
        end
        @scheduler = DEVS.scheduler.new(selected)

        @time_last = max_time_last
        @time_next = min_time_next
      end

      def handle_collect_event(event)
        if event.time == @time_next
          @time_last = event.time

          imm = imminent_children
          i = 0
          while i < imm.size
            child = imm[i]
            child.dispatch(event)
            @synchronize[child] = true
            i += 1
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

        i = 0
        while i < bag.size
          message = bag[i]
          payload, port = *message

          # check internal coupling to get children who receive sub-bag of y
          j = 0
          ic = model.internal_couplings(port)
          while j < ic.size
            coupling = ic[j]
            receiver = coupling.destination.processor
            child_bags[receiver] << Message.new(payload, coupling.destination_port)
            @synchronize[receiver] = true
            j += 1
          end

          # check external coupling to form sub-bag of parent output
          j = 0
          oc = model.output_couplings(port)
          while j < oc.size
            parent_bag << Message.new(payload, oc[j].destination_port)
            j += 1
          end

          i += 1
        end

        i = 0
        receivers = child_bags.keys
        while i < receivers.size
          receiver = receivers[i]
          sub_bag = child_bags[receiver]
          unless sub_bag.empty?
            receiver.dispatch(Event.new(:input, event.time, sub_bag))
          end
          i += 1
        end

        unless parent_bag.empty?
          parent.dispatch(Event.new(:output, event.time, parent_bag))
        end
      end

      def handle_input_event(event)
        @bag.concat(event.bag)
      end

      def handle_internal_event(event)
        if (@time_last..@time_next).include?(event.time)
          child_bags = Hash.new { |hash, key| hash[key] = [] }
          bag = @bag

          i = 0
          while i < bag.size
            message = bag[i]
            payload, port = *message

            # check external input couplings to get children who receive sub-bag of y
            j = 0
            ic = model.input_couplings(port)
            while j < ic.size
              coupling = ic[j]
              receiver = coupling.destination.processor
              child_bags[receiver] << Message.new(payload, coupling.destination_port)
              @synchronize[receiver] = true
              j += 1
            end

            i += 1
          end

          i = 0
          receivers = child_bags.keys
          while i < receivers.size
            receiver = receivers[i]
            sub_bag = child_bags[receiver]
            unless sub_bag.empty?
              receiver.dispatch(Event.new(:input, event.time, sub_bag))
            end
            i += 1
          end
          bag.clear

          flagged = @synchronize.keys
          i = 0
          while i < flagged.size
            child = flagged[i]
            @scheduler.unschedule(child)
            child.dispatch(Event.new(:internal, event.time))
            @scheduler.schedule(child) if child.time_next < DEVS::INFINITY
            i += 1
          end
          @synchronize.clear

          @time_last = event.time
          @time_next = min_time_next
        else
          raise BadSynchronisationError, "time: #{event.time} should be between time_last: #{@time_last} and time_next: #{@time_next}"
        end
      end
    end
  end
end
