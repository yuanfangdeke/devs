require 'minitest/autorun'
require 'minitest/mock'

require 'devs'

include DEVS

class TestDispatcher < MiniTest::Unit::TestCase
  def setup
    @dispatcher = Dispatcher.new
    @dispatcher.run!
  end

  def teardown
    @dispatcher.stop
  end

  def test_dispatch
    mocks = []

    4.times do
      processor_mock = MiniTest::Mock.new
      event_mock = MiniTest::Mock.new

      event_mock.expect(:dup, event_mock)
      processor_mock.expect(:dispatch, nil, [event_mock])

      @dispatcher.dispatch(processor_mock, event_mock)

      mocks << processor_mock
      mocks << event_mock
    end
    sleep 2

    mocks.each { |mock| mock.verify }
  end

end
