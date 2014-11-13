require 'test_helper'
require 'minitest/autorun'
require 'devs'

class Ev
  attr_accessor :time_next
  def initialize(tn)
    @time_next = tn
  end
end

class TestSplayTree < MiniTest::Test
  def setup
    @tree = DEVS::SplayTree.new
  end

  def test_push
    n = 100
    (0...n).map { |i| Ev.new(i) }
       .shuffle
       .each { |ev| @tree << ev }

    assert_equal n, @tree.size
  end

  def test_priority
    events = [Ev.new(2), Ev.new(12), Ev.new(257)]
    events.each { |ev| @tree.push(ev) }
    assert_equal 2, @tree.pop.time_next
    @tree.push(Ev.new(0))
    assert_equal 0, @tree.pop.time_next
    assert_equal 12, @tree.pop.time_next
    assert_equal 257, @tree.pop.time_next
  end

  def test_empty
    assert_equal nil, @tree.pop
    assert_equal nil, @tree.delete(Ev.new(10))
    assert_equal nil, @tree.peek
    assert_equal 0, @tree.size
  end

  def test_peek
    n = 30
    (0...n).map { |i| Ev.new(i) }
           .shuffle
           .each { |ev| @tree << ev }

    assert_equal n, @tree.size
    assert_equal 0, @tree.peek.time_next
    assert_equal n, @tree.size
  end
end
