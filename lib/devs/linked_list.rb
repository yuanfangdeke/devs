module DEVS
  class LinkedList
    include Enumerable

    attr_reader :size

    Node = Struct.new(:value, :previous, :next)

    def initialize(elements = nil)
      @head = nil
      @tail = nil
      @size = 0
      push(*elements)
    end

    # Append (O(1)) — Pushes the given object(s) on to the end of this list. This
    # expression returns the list itself, so several appends may be chained
    # together. See also {#pop} for the opposite effect.
    def push(*values)
      values.each do |v|
        node = Node.new(v)
        if @head.nil?
          @head = @tail = node
        else
          node.previous = @tail
          @tail.next = node
          @tail = node
        end
        @size += 1
      end
      self
    end

    # Append (0(1)) - Pushes the given object(s) on to the beginning of this list.
    # This expression returns the list itself, so several appends may be chained
    # together.
    #
    # See also {#take} for the opposite effect.
    def push_front(*values)
      values.each do |v|
        node = Node.new(v)
        if @head.nil?
          @head = @tail = node
        else
          node.next = @head
          @head.previous = node
          @head = node
        end
        @size += 1
      end
      self
    end

    # Removes (O(1)) the first element from self and returns it, or nil if the
    # list is empty.
    #
    # See also {#push_front} for the opposite effect
    def take
      return nil if @size.zero?

      item = @head.value
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
      return nil if @size.zero?

      item = @tail.value
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

    # Deletes (O(n)) first item from self that is equal to v.
    #
    # Returns the deleted item, or nil if no matching item is found.
    def delete(v)
      if @head.nil?
        nil
      elsif v == @head.value
        item = @head.value
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
        while node && v != node.value
          node = node.next
        end

        if node == @tail
          item = @tail.value
          @tail = @tail.previous
          @tail.next = nil
          @size -= 1
          item
        elsif node
          item = node.value
          node.previous.next = node.next
          node.next.previous = node.previous
          @size -= 1
          item
        else
          nil
        end
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
