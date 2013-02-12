require 'minitest/autorun'
require 'minitest/colorer'

require 'devs'

include DEVS

class TestPort < MiniTest::Unit::TestCase
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
end
