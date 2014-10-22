require 'test_helper'
require 'minitest/autorun'
require 'devs'

class TestCalendarQueue < MiniTest::Test
  def setup
    @queue = DEVS::CalendarQueue.new
  end

  def test_push
    n = 100
    (0...n).map { |i| Ev.new(i) }
       .shuffle
       .each { |ev| @queue << ev }

    assert_equal n, @queue.size
  end

  def test_priority
    events = [Ev.new(2), Ev.new(12), Ev.new(257)]
    events.each { |ev| @queue.push(ev) }
    assert_equal 2, @queue.pop.time_next
    @queue.push(Ev.new(0))
    assert_equal 0, @queue.pop.time_next
    assert_equal 12, @queue.pop.time_next
    assert_equal 257, @queue.pop.time_next
  end

  def test_empty
    assert_equal nil, @queue.pop
    assert_equal nil, @queue.delete(Ev.new(10))
    assert_equal nil, @queue.peek
    assert_equal 0, @queue.size
  end

  def test_adjust
    events = [ Ev.new(2), Ev.new(12), Ev.new(257) ]
    events.each { |e| @queue.push(e) }

    ev = @queue.delete(events[1])

    refute_nil ev
    assert_equal 12, ev.time_next

    ev.time_next = 0
    @queue.push(ev)

    assert_equal 0, @queue.pop.time_next
  end

  def test_peek
    n = 30
    (0...n).map { |i| Ev.new(i) }
           .shuffle
           .each { |ev| @queue << ev }

    assert_equal n, @queue.size
    assert_equal 0, @queue.peek.time_next
    assert_equal n, @queue.size
  end
end
