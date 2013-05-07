module DEVS
  module Parallel
    module MasterCoordinatorStrategy
      # def initialize(model)
      #   super(model)

      #   @bag = []
      #   @synchronize = Set.new
      # end

      # def dispatch(event)
      #   super(event)

      #   case event.type
      #   when :'@' then handle_collect_event(event)
      #   when :d then handle_done_event(event)
      #   end
      # end

      def handle_collect_event(event)
        if event.time == @time_next
          @time_last = event.time

          children = imminent_children
          children.each do |child|
            @synchronize << child
            child.dispatch(event)
          end

          #wait until ( done, t )’s have been received from all im- minent processors
          #send ( done, t ) to parent coordinator
        else
          raise BadSynchronisationError,
                "time: #{event.time} should match time_next: #{@time_next}"
        end
      end
    end
  end
end
