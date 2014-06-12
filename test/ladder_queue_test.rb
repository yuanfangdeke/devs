require 'test_helper'

require 'minitest/autorun'

require 'devs'

Ev = Struct.new(:time_next)

class TestLadderQueue < MiniTest::Test
  def setup
    @queue = DEVS::LadderQueue.new
  end

  def test_push
    n = 100
    @queue.push(*(0...n).map { |i| Ev.new(i) }.shuffle)

    assert_equal n, @queue.top_size
    assert_equal n, @queue.size
    assert_equal 0, @queue.bottom_size
    assert_equal 0, @queue.active_rungs
  end

  def test_ladder_spawn
    events = [0.6, 0.5, 3.1, 3.05, 3.3, 3.4, 3.0, 4.5].map{ |i| Ev.new(i) }
    # use a threshold of 4
    queue = DEVS::LadderQueue.new(events, 4)
    delta = 0.0001

    assert_equal 0, queue.active_rungs

    assert_in_delta 0.5, queue.pop.time_next, delta
    assert_equal 1, queue.active_rungs

    assert_in_delta 0.6, queue.pop.time_next, delta
    assert_equal 1, queue.active_rungs

    assert_in_delta 3.0, queue.pop.time_next, delta
    assert_equal 2, queue.active_rungs
  end

  def test_priority
    events = [Ev.new(2), Ev.new(12), Ev.new(Float::INFINITY)]
    events.each { |ev| @queue.push(ev) }

    assert_equal 2, @queue.peek.time_next
    @queue.push(Ev.new(0))
    assert_equal 0, @queue.peek.time_next
  end

  def test_pop
    n = 30
    @queue.push(*(0...n).map { |i| Ev.new(i) }.shuffle)

    assert_equal n, @queue.size

    assert_equal 0, @queue.pop.time_next
    assert_equal 1, @queue.pop.time_next
  end

  def test_empty
    assert_equal nil, @queue.pop
    @queue.push(Ev.new(10))
    assert_equal 10, @queue.pop.time_next
    assert_equal nil, @queue.pop
  end

  def test_peek
    n = 30
    @queue.push(*(0...n).map { |i| Ev.new(i) }.shuffle)

    assert_equal n, @queue.size
    assert_equal 0, @queue.peek.time_next
    assert_equal n, @queue.size
  end

  def test_infinite_spawn_guard
    n = 100
    max = 50
    min = 0
    @queue.push(*(0...n).map { Ev.new(rand(max - min) + min) }.shuffle)

    assert_raises(LadderQueue::RungOverflowError) { @queue.pop }
    assert_raises(LadderQueue::RungOverflowError) { @queue.peek }
  end

  def test_infinity
    n = 10_000
    max = Float::MAX
    min = 0
    @queue.push(Ev.new(Float::INFINITY))
    @queue.push(*(0...n).map { Ev.new(rand(max - min) + min) }.shuffle)

    @queue.pop
    @queue.pop
    @queue.pop
    @queue.pop
    @queue.pop
  end

  def test_adjust
    events = [ Ev.new(2), Ev.new(12), Ev.new(INFINITY) ]
    events.each { |e| @queue.push(e) }

    assert_equal 2, @queue.peek.time_next

    ev = @queue.delete(events[1])

    refute_nil ev
    assert_equal 12, ev.time_next

    ev.time_next = 0
    @queue.push(ev)

    assert_equal 0, @queue.peek.time_next
  end

  def test_bottom_overflow
    n = 100
    @queue.push(*(0...n).map { |i| Ev.new(0) }.shuffle)

    assert_equal n, @queue.size
    assert_equal n, @queue.top_size
    assert_equal 0, @queue.bottom_size

    assert_equal 0, @queue.peek.time_next

    assert_equal n, @queue.bottom_size
    assert_equal 0, @queue.top_size
  end

end
