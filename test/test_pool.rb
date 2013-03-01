$VERBOSE = true
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__) if $0 == __FILE__
require 'rubygems'
require 'minitest/autorun'
require 'proco'

class TestPool < MiniTest::Unit::TestCase
  def test_pool
    pool = Proco::MT::Pool.new(8)
    cnt = 0
    mtx = Mutex.new
    1000.times do
      pool.assign { mtx.synchronize { cnt += 3 } }
    end
    pool.exit
    assert_equal 1000, pool.counter
    assert_equal 3000, cnt
  end
end

