module DEVS
  class LinkedList
    include Enumerable

    attr_reader :size, :head, :tail

    class Node
      attr_accessor :value, :previous, :next
      def initialize(v=nil, p=nil, n=nil)
        @value = v
        @previous = p
        @next = n
      end
    end

    def initialize(size = 0)
      @head = nil
      @tail = nil
      @size = 0

      if block_given? && size > 0
        i = 0
        while i < size
          self << yield(i)
          i += 1
        end
      end
    end

    def clear
      @head = nil
      @tail = nil
      @size = 0
    end

    def empty?
      @size == 0
    end

    # Append (O(1)) — Pushes the given object(s) on to the end of this list. This
    # expression returns the list itself, so several appends may be chained
    # together. See also {#pop} for the opposite effect.
    def <<(obj)
      obj = obj.value if obj.is_a?(Node)
      node = Node.new(obj)

      if @head.nil?
        @head = @tail = node
      else
        node.previous = @tail
        @tail.next = node
        @tail = node
      end
      @size += 1
      self
    end
    alias_method :push, :<<

    # Append (0(1)) - Pushes the given object(s) on to the beginning of this list.
    # This expression returns the list itself, so several appends may be chained
    # together.
    #
    # See also {#take} for the opposite effect.
    def push_front(obj)
      obj = obj.value if obj.is_a?(Node)
      node = Node.new(obj)

      if @head.nil?
        @head = @tail = node
      else
        node.next = @head
        @head.previous = node
        @head = node
      end
      @size += 1
      self
    end

    # Removes (O(1)) the first element from self and returns it, or nil if the
    # list is empty.
    #
    # See also {#push_front} for the opposite effect
    def shift
      return nil if @size == 0

      item = @head
      if @head == @tail
        @head = nil
        @tail = nil
      else
        @head = @head.next
        @head.previous = nil
      end
      @size -= 1
      item
    end

    # Removes (O(1)) the last element from self and returns it, or nil if the
    # list is empty.
    #
    # See also {#push} for the opposite effect.
    def pop
      return nil if @size == 0

      item = @tail
      if @tail == @head
        @tail = nil
        @head = nil
      else
        @tail = @tail.previous
        @tail.next = nil
      end
      @size -= 1
      item
    end

    # Deletes first item from self that is equal to v.
    #
    # Returns the deleted item, or nil if no matching item is found.
    def delete(obj)
      if @head == nil
        nil
      elsif obj == @head.value
        item = @head
        if @head == @tail
          @head = nil
          @tail = nil
        else
          @head = @head.next
          @head.previous = nil
        end
        @size -= 1
        item
      else
        node = @head.next
        while node && obj != node.value
          node = node.next
        end

        if node == @tail
          item = @tail
          @tail = @tail.previous
          @tail.next = nil
          @size -= 1
          item
        elsif node
          item = node
          node.previous.next = node.next
          node.next.previous = node.previous
          @size -= 1
          item
        else
          nil
        end
      end
    end

    def concat(list)
      if list.is_a?(LinkedList)
        n = list.head
        while n
         self << n.value
         n = n.next
        end
      else
        i = 0
        while i < list.size
          self << list[i]
          i += 1
        end
      end
      self
    end

    # Inserts (O(1)) the given object before the element with the given node.
    def insert_before(node, obj)
      obj = obj.value if obj.is_a?(Node)
      node = Node.new(obj)

      if @head == node
        @head = new_node
        new_node.next = node
      else
        previous = node.previous
        previous.next = new_node
        new_node.previous = previous
        new_node.next = node
      end
      self
    end

    def first
      if @head
        @head.value
      else
        nil
      end
    end

    def last
      if @last
        @last.value
      else
        nil
      end
    end

    # Calls the given block once for each element in <tt>self</tt>, passing that
    # element as a parameter.
    def each
      return enum_for(:each) unless block_given?
      n = @head
      while n
        yield n.value
        n = n.next
      end
    end
  end
end
