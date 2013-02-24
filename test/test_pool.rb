$VERBOSE = true
require 'rubygems'
require 'minitest/autorun'
require 'proco'

class TestPool < MiniTest::Unit::TestCase
  def test_pool
    pool = Proco::MT::Pool.new(4)
    cnt = 0
    pool.assign { cnt += 1 }
    pool.assign { cnt += 2 }
    pool.assign { cnt += 3 }
    pool.exit
    assert_equal 3, pool.counter
    assert_equal 6, cnt
  end
end

