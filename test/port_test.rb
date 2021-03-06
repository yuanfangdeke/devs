require 'test_helper'

require 'minitest/autorun'

require 'devs'

include DEVS

class TestPort < MiniTest::Test
  def setup
    @input_port = Port.new(nil, :input, :p0)
    @output_port = Port.new(nil, :output, :p1)
  end

  def test_input
    assert @input_port.input?
    refute @output_port.input?
  end

  def test_output
    refute @input_port.output?
    assert @output_port.output?
  end

  def test_checks_type
    assert_raises(ArgumentError) do
      Port.new(nil, :chalabala, :p2)
    end
  end

  def test_is_quite_permissive
    p2 = Port.new(nil, 'InPut', :p2)
    p3 = Port.new(nil, 'OUTPUT', :p3)

    assert p2.input?
    assert p3.output?
  end

  def test_cant_set_outgoing_value_twice_unless_read
    @output_port.drop_off(:smthg)
    assert_raises(MessageAlreadySentError) do
      @output_port.drop_off(:smthg_else)
    end
    assert_equal(:smthg, @output_port.pick_up)
  end
end
