module DEVS
  module TimeWarp
    module CoordinatorStrategy
      def handle_rollback_event(event)
        children_ahead(event.time).each do |child|
          child.dispatch(event)
        end

        @time_last = max_time_last
        @time_next = min_time_next
      end

      def children_ahead(time)
        children.select { |child| child.time_last > time }
      end

      def fossil_collection(gvt)
        @children.each { |child| child.fossil_collection(gvt) }
      end
    end
  end
end
