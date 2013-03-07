require 'minitest/autorun'

require 'devs'

include DEVS

class TestLatch < MiniTest::Unit::TestCase

  def test_requires_positive_count
    assert_raises(ArgumentError) { Latch.new(-1) }
    assert_raises(ArgumentError) do
      latch = Latch.new(0)
      latch.count = -1
    end
  end

  def test_count_should_be_zero_to_reset_latch_count
    latch = Latch.new(2)
    Thread.new { latch.wait }
    latch.release
    assert_equal(1, latch.count)

    assert_raises(RuntimeError) { latch.count = 5 }
  end

  def test_can_reset_count_when_zero_has_been_reached
    latch = Latch.new(2)
    2.times { Thread.new { latch.release } }
    latch.wait

    assert_equal(0, latch.count)
    latch.count = 5
    assert_equal(5, latch.count)
  end

  def test_basic_latch_usage
    latch = Latch.new(1)
    name = "foo"
    Thread.new do
      name = "bar"
      latch.release
    end
    latch.wait
    assert_equal(0, latch.count)
    assert_equal("bar", name)
  end

  def test_basic_latch_usage_inverted
    latch = Latch.new(1)
    name = "foo"
    Thread.new do
      latch.wait
      assert_equal(0, latch.count)
      assert_equal("bar", name)
    end
    name = "bar"
    latch.release
  end

  def test_count_down_from_zero_skips_wait
    latch = Latch.new(0)
    latch.wait
    assert_equal(0, latch.count)
  end

  def test_count_down_twice_with_thread
    latch = Latch.new(2)
    name = "foo"
    Thread.new do
      latch.release
      name = "bar"
      latch.release
    end
    latch.wait
    assert_equal(0, latch.count)
    assert_equal("bar", name)
  end

  def test_count_down_twice_with_two_parallel_threads
    latch = Latch.new(2)
    name = "foo"
    Thread.new { latch.release }
    Thread.new do
      name = "bar"
      latch.release
    end
    latch.wait
    assert_equal(0, latch.count)
    assert_equal("bar", name)
  end

  def test_count_down_twice_with_two_chained_threads
    latch = Latch.new(2)
    name = "foo"
    Thread.new do
      latch.release
      Thread.new do
        name = "bar"
        latch.release
      end
    end
    latch.wait
    assert_equal(0, latch.count)
    assert_equal("bar", name)
  end

  def test_count_down_with_multiple_waiters
    proceed_latch = Latch.new(2)
    check_latch = Latch.new(2)
    results = {}
    Thread.new do
      proceed_latch.wait
      results[:first] = 1
      check_latch.release
    end
    Thread.new do
      proceed_latch.wait
      results[:second] = 2
      check_latch.release
    end
    assert_equal({}, results)
    proceed_latch.release
    proceed_latch.release
    check_latch.wait
    assert_equal(0, proceed_latch.count)
    assert_equal(0, check_latch.count)
    assert_equal({:first => 1, :second => 2}, results)
  end

  def test_interleaved_latches
    change_1_latch = Latch.new(1)
    check_latch = Latch.new(1)
    change_2_latch = Latch.new(1)
    name = "foo"
    Thread.new do
      name = "bar"
      change_1_latch.release
      check_latch.wait
      name = "man"
      change_2_latch.release
    end
    change_1_latch.wait
    assert_equal("bar", name)
    check_latch.release
    change_2_latch.wait
    assert_equal("man", name)
  end
end
