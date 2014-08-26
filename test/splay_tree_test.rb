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

  def test_inserts
    events = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9].map { |i| Ev.new(i) }

  end
end
