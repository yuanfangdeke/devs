module DEVS
  module SequentialParallel
    module CoordinatorImpl
      def after_initialize
        @influencees = Hash.new { |hsh, key| hsh[key] = [] }
        @synchronize = {}
        @parent_bag = []
        @bag = []
        @imm = [] unless DEVS.scheduler == MinimalListScheduler
      end

      def init(time)
        i = 0
        selected = []
        min = DEVS::INFINITY
        while i < @children.size
          child = @children[i]
          tn = child.init(time)
          selected.push(child) if tn < DEVS::INFINITY
          min = tn if tn < min
          i += 1
        end
        @scheduler = if DEVS.scheduler == MinimalListScheduler
          DEVS.scheduler.new(@children)
        else
          DEVS.scheduler.new(selected)
        end

        @time_last = max_time_last
        @time_next = min
      end

      def collect(time)
        if time != @time_next
          raise BadSynchronisationError, "\ttime: #{time} should match time_next: #{@time_next}"
        end
        @time_last = time

        @bag.clear
        imm = if DEVS.scheduler == MinimalListScheduler
          read_imminent_children
        else
          @imm = imminent_children
        end
        i = 0
        while i < imm.size
          child = imm[i]
          @bag.concat(child.collect(time))
          @synchronize[child] = true
          i += 1
        end

        # keep internal couplings and send EOC up
        @parent_bag.clear

        i = 0
        while i < @bag.size
          message = @bag[i]
          payload, port = message.payload, message.port

          # check internal coupling to get children who receive sub-bag of y
          j = 0
          ic = @model.internal_couplings(port)
          while j < ic.size
            coupling = ic[j]
            receiver = coupling.destination.processor
            @influencees[receiver] << Message.new(payload, coupling.destination_port)
            @synchronize[receiver] = true
            j += 1
          end

          # check external coupling to form sub-bag of parent output
          j = 0
          oc = @model.output_couplings(port)
          while j < oc.size
            @parent_bag << Message.new(payload, oc[j].destination_port)
            j += 1
          end

          i += 1
        end

        @parent_bag
      end

      def remainder(time, bag)
        i = 0
        while i < bag.size
          message = bag[i]
          payload, port = message.payload, message.port

          # check external input couplings to get children who receive sub-bag of y
          j = 0
          ic = @model.input_couplings(port)
          while j < ic.size
            coupling = ic[j]
            receiver = coupling.destination.processor
            @influencees[receiver] << Message.new(payload, coupling.destination_port)
            @synchronize[receiver] = true
            j += 1
          end

          i += 1
        end

        influencees = @synchronize.keys
        i = 0
        while i < influencees.size
          receiver = influencees[i]
          sub_bag = @influencees[receiver]
          if DEVS.scheduler == MinimalListScheduler
            receiver.remainder(time, sub_bag)
          else
            @scheduler.cancel(receiver) if receiver.time_next < DEVS::INFINITY && !@imm.include?(receiver)
            tn = receiver.remainder(time, sub_bag)
            @scheduler.insert(receiver) if tn < DEVS::INFINITY
          end
          sub_bag.clear
          i += 1
        end
        @synchronize.clear
        @scheduler.reschedule! if DEVS.scheduler == MinimalListScheduler

        @time_last = time
        @time_next = min_time_next
      end
    end
  end
end
