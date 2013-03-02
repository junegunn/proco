$VERBOSE = true
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__) if $0 == __FILE__
require 'rubygems'
require 'minitest/autorun'
require 'proco'

class TestWorker < MiniTest::Unit::TestCase
  def test_worker
    w = Proco::MT::Worker.new nil
    cnt = 0
    w.assign { sleep 0.1; cnt += 1 }
    w.assign { sleep 0.1; cnt += 1 }
    w.assign { sleep 0.1; cnt += 1 } # Async
    assert_equal 1, cnt
    sleep 0.2;
    w.exit
    assert_equal 3, cnt
  end
end
