$VERBOSE = true
require 'rubygems'
require 'minitest/autorun'
require 'proco'

class TestWorker < MiniTest::Unit::TestCase
  def test_worker
    w = Proco::MT::Worker.new
    cnt = 0
    w.assign { sleep 0.1; cnt += 1 }
    w.assign { sleep 0.1; cnt += 1 }
    w.assign { sleep 0.1; cnt += 1 } # Async
    assert_equal 2, cnt
    sleep 0.2;
    w.exit
    assert_equal 3, cnt
  end
end
