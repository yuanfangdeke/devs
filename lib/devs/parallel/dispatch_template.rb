module DEVS
  module Parallel
    module DispatchTemplate
      def dispatch(event)
        super(event)

        case event.type
        when :i then handle_init_event(event)
        when :* then handle_star_event(event)
        when :x then handle_input_event(event)
        when :y then handle_output_event(event)
        when :'@' then handle_collect_event(event)
        end
      end
    end
  end
end
