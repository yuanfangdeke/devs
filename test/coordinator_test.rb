require 'minitest/autorun'
require 'minitest/mock'

require 'devs'

include DEVS

class TestCoordinator < MiniTest::Unit::TestCase
  def setup
    @model = MiniTest::Mock.new
    @coordinator = Coordinator.new(@model)
    @first_child = MiniTest::Mock.new
    @second_child = MiniTest::Mock.new
    @coordinator.add_child(@first_child)
    @coordinator.add_child(@second_child)
  end

  def test_min_time_next
    @first_child.expect(:time_next, 3)
    @second_child.expect(:time_next, 10)

    assert_equal(3, @coordinator.send(:min_time_next))

    #@first_child.verify
    #@second_child.verify
  end
end
