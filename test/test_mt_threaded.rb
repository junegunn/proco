$VERBOSE = true
require 'rubygems'
require 'minitest/autorun'
require 'proco'

class MTThreadedSub
  include Proco::MT::Threaded

  def initialize
    super
  end
end

class TestMTThreaded < MiniTest::Unit::TestCase
  def test_mt_base
    t = MTThreadedSub.new
    assert_equal false, t.running?
    status = nil
    t.spawn do
      while t.running?
        sleep 0.01
      end
      status = :done
    end
    assert_equal true, t.running?
    t.exit
    assert_equal :done, status
    assert_equal false, t.running?
  end
end

