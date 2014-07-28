require 'test_helper'
require 'minitest/autorun'
require 'devs'

class Ev
  attr_accessor :time_next
  def initialize(tn)
    @time_next = tn
  end
end

class TestLadderQueue < MiniTest::Test
  def setup
    @queue = DEVS::LadderQueue.new
  end

  def test_push
    n = 100
    (0...n).map { |i| Ev.new(i) }
       .shuffle
       .each { |ev| @queue << ev }

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
    (0...n).map { |i| Ev.new(i) }
       .shuffle
       .each { |ev| @queue << ev }

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
    (0...n).map { |i| Ev.new(i) }
           .shuffle
           .each { |ev| @queue << ev }

    assert_equal n, @queue.size
    assert_equal 0, @queue.peek.time_next
    assert_equal n, @queue.size
  end

  def test_infinite_spawn_guard
    n = 100
    max = 50
    min = 0
    (0...n).map { |i| Ev.new(rand(max - min) + min) }
       .shuffle
       .each { |ev| @queue << ev }

    #assert_raises(LadderQueue::RungOverflowError) { @queue.pop }
    #assert_raises(LadderQueue::RungOverflowError) { @queue.peek }
  end

  def test_rand
    n = 500
    max = 100
    min = 1
    (0...n).map { |i| Ev.new(rand(max - min) + min) }
       .shuffle
       .each { |ev| @queue << ev }
    assert_equal n, @queue.size
    expected = n

    time = 0
    stored = nil
    while time < 20
      a = []
      a << stored if stored
      while @queue.size > 0
        stored = @queue.pop
        break if stored.time_next == time
        a << stored
        stored = nil
      end
      #a << @queue.pop while @queue.size > 0 && @queue.peek.time_next == time
      a.each do |ev|
        if rand > 0.5
          expected -= 1
        else
          ev.time_next = rand(max - min) + min
          @queue.push(ev)
        end
      end
      time = @queue.peek.time_next
    end
    assert_equal expected, @queue.size
  end

  def test_infinity
    n = 10_000
    max = Float::MAX
    min = 0
    @queue.push(Ev.new(Float::INFINITY))
    (0...n).map { |i| Ev.new(rand(max - min) + min) }
       .shuffle
       .each { |ev| @queue << ev }

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

  def test_adjust2
    components = [Ev.new(0), Ev.new(INFINITY), Ev.new(INFINITY), Ev.new(INFINITY), Ev.new(INFINITY)]
    components.each { |e| @queue.push(e) }
    assert_equal 5, @queue.size

    time = 0

    imm = []
    imm << @queue.pop while @queue.peek.time_next == time

    assert_equal 1, imm.size
    ev = imm.first
    refute_nil ev
    assert_equal 0, ev.time_next
    assert_equal 4, @queue.size

    components[1,3].each do |c|
      item = @queue.delete(c)
      refute_nil item
      assert_equal c, item
      assert_equal 3, @queue.size
      item.time_next = 1
      @queue.push(item)
      assert_equal 4, @queue.size
    end

    ev.time_next = 1
    @queue.push(ev)
    assert_equal 5, @queue.size

    time = 1
    imm.clear
    imm << @queue.pop while @queue.peek.time_next == time
    assert_equal 4, imm.size
    assert_equal 1, @queue.size
  end

  def test_bottom_overflow
    n = 100
    (0...n).map { |i| Ev.new(0) }
       .shuffle
       .each { |ev| @queue << ev }

    assert_equal n, @queue.size
    assert_equal n, @queue.top_size
    assert_equal 0, @queue.bottom_size

    assert_equal 0, @queue.peek.time_next

    assert_equal n, @queue.bottom_size
    assert_equal 0, @queue.top_size
  end

end
