require 'test_helper'

require 'minitest/autorun'

require 'devs'

class TestAtomicModel < MiniTest::Test
  def setup
    @model = AtomicModel.new
  end

  def test_atomic
    assert @model.atomic?
    refute @model.coupled?
  end
end
