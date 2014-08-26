module DEVS
  class SplayTree
    class Node
      attr_accessor :value, :left, :right
      def initialize(v, l=nil, r=nil)
        @value = v
        @left = l
        @right = r
      end
    end

    attr_reader :size

    def initialize(elements = nil)
      @header = Node.new(nil)
      @size = 0
      if elements
        i = 0
        while i < elements.size
          self << elements[i]
          i += 1
        end
      end
    end

    def empty?
      @root == nil
    end

    def <<(obj)
      @size += 1
      if @root
        splay(obj)
        tn = obj.time_next
        if tn == @root.value.time_next
          @root.value = obj
        else
          n = Node.new(obj)
          if tn < @root.value.time_next
            n.left = @root.left
            n.right = @root
            @root.left = nil
          else
            n.right = @root.right
            n.left = @root
            @root.right = nil
          end
          @root = n
        end
      else
        @root = Node.new(obj)
      end
    end

    def delete(obj)
      splay(obj)
      tn = obj.time_next

      if tn != @root.value.time_next
        raise "#{tn} not found in tree"
      end

      @size -= 1
      unless @root.left
        @root = @root.right
      else
        x = @root.right
        @root = @root.left
        splay(obj)
        @root.right = x
      end
    end

    # def find_max
    #   if @root
    #     x = @root
    #     x = x.right while x.right
    #     splay(x.value)
    #     x.value
    #   else
    #     nil
    #   end
    # end

    def find_min
      if @root
        x = @root
        x = x.left while x.left
        splay(x.value)
        x.value
      else
        nil
      end
    end

    def pop_min
      if @root
        x = @root
        x = x.left while x.left
        delete(x.value)
      else
        nil
      end
    end

    def splay(obj)
      l = r = @header
      t = @root
      @header.left = @header.right = nil
      tn = obj.time_next

      while true
        if tn < t.value.time_next
          break unless t.left
          if tn < t.left.value.time_next
            y = t.left
            t.left = y.right
            y.right = t
            t = y
            break unless t.left
          end
          r.left = t
          r = t
          t = t.left
        elsif tn > t.value.time_next
          break unless t.right
          if tn > t.right.value.time_next
            y = t.right
            t.right = y.left
            y.left = t
            t = y
            break unless t.right
          end
          l.right = t
          l = t
          t = t.right
        else
          break
        end
        l.right = t.left
        r.left = t.right
        t.left = @header.right
        t.right = @header.left
        @root = t
      end
    end
  end
end
