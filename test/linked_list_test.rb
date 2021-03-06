require 'test_helper'

require 'minitest/autorun'

require 'devs'

class TestLinkedList < MiniTest::Test
  def setup
    @list = DEVS::LinkedList.new
  end

  def test_size
    assert_equal 0, @list.size

    @list << 1 << 2 << 3
    assert_equal 3, @list.size

    @list.push_front(4)
         .push_front(5)
         .push_front(6)
    assert_equal 6, @list.size

    @list.pop
    assert_equal 5, @list.size

    @list.shift
    assert_equal 4, @list.size

    @list.delete(4)
    assert_equal 3, @list.size

    @list.pop
    @list.pop
    @list.shift

    assert_equal 0, @list.size
    @list.pop
    assert_equal 0, @list.size
    @list.shift
    assert_equal 0, @list.size
  end

  def test_push
    @list << 1 << 2 << 3
    assert_equal [1, 2, 3], @list.to_a
  end

  def test_push_front
    @list.push_front(1)
         .push_front(2)
         .push_front(3)
    assert_equal [3, 2, 1], @list.to_a
  end

  def test_pop
    @list << 1 << 2 << 6
    assert_equal 6, @list.pop.value
    assert_equal [1, 2], @list.to_a
    @list.pop
    @list.pop
    assert_equal nil, @list.pop
    assert_equal [], @list.to_a
  end

  def test_take
    @list << 1 << 2 << 6

    assert_equal 1, @list.shift.value
    assert_equal [2, 6], @list.to_a

    assert_equal 2, @list.shift.value
    assert_equal 6, @list.shift.value

    assert_equal nil, @list.shift
    assert_equal [], @list.to_a
  end

  def test_delete
    @list << 1 << 2 << 3 << 4

    assert_equal nil, @list.delete(8)
    assert_equal 1, @list.delete(1).value
    assert_equal [2, 3, 4], @list.to_a
    assert_equal 4, @list.delete(4).value
    assert_equal [2, 3], @list.to_a
  end
end
