require 'test_helper'

require 'minitest/autorun'

require 'devs'

include DEVS

class TestEvent < MiniTest::Test
  def test_checks_time
    assert_raises(ArgumentError) do
      Event.new(:internal, -42)
    end
  end
end
