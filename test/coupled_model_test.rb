require 'test_helper'

require 'minitest/autorun'

require 'devs'

class TestCoupledModel < MiniTest::Test
  def setup
    @model = CoupledModel.new
  end

  def test_coupled
    assert @model.coupled?
    refute @model.atomic?
  end
end
