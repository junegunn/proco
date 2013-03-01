$VERBOSE = true
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__) if $0 == __FILE__
require 'rubygems'
require 'minitest/autorun'
require 'proco'
require 'parallelize'
require 'logger'

describe Proco do
  before do
    @logger = Logger.new($stdout)
  end

  it "can be created with method chaining" do
    proco = Proco.interval(1).threads(4).queues(4).queue_size(100).batch(true).logger(@logger).new
    opts = proco.options

    assert_equal 1,       opts[:interval]
    assert_equal 4,       opts[:threads]
    assert_equal 4,       opts[:queues]
    assert_equal 100,     opts[:queue_size]
    assert_equal true,    opts[:batch]
    assert_equal @logger, opts[:logger]

    proco = Proco.threads(8).interval(10).new(:interval => 20)
    opts = proco.options
    assert_equal 20, opts[:interval]
    assert_equal 8,  opts[:threads]
  end

  describe "in default setting" do
    before do
      @proco = Proco.new
    end

    it "yields each item" do
      @proco.start do |items|
        assert_equal false, items.is_a?(Array)
      end

      @proco.submit! 1
      @proco.submit 2

      @proco.exit
    end

    it "acts as a FCFS queue" do
      processed = []
      @proco.start do |item|
        processed << item
      end

      feed = []
      100.times do |i|
        feed << i
        @proco.submit! i
      end

      @proco.exit

      assert_equal feed, processed
      assert_equal 100, processed.length
    end
  end

  describe "in batch-mode with multiple queues" do
    before do
      @proco = Proco.queue_size(10).queues(2).threads(4).batch(true).logger(@logger).new
    end

    it "always yields Array" do
      bool = true
      @proco.start do |items|
        assert items.is_a?(Array)
      end
      @proco.submit 1
      @proco.submit 2
      @proco.submit! 3

      @proco.exit
    end

    it "handles synchronous requests" do
      cnt = 0
      @proco.start do |items|
        cnt += items.inject(:+)
      end
      1000.times { |i| @proco.submit i }
      assert_equal 1000.times.inject(:+), cnt

      @proco.exit
    end

    it "handles asynchronous requests" do
      cnt = 0
      @proco.start do |items|
        cnt += items.inject(:+)
      end
      1000.times { |i| @proco.submit! i }
      @proco.exit
      assert_equal 1000.times.inject(:+), cnt
    end
  end
end

class TestProco # < MiniTest::Unit::TestCase

# def test_proco_lifecycle
#   proco = Proco.interval(0.1).threads(4).queues(8).queue_size(10).new

#   assert_equal false, proco.running?

#   # No you can't submit an item yet
#   assert_raises(RuntimeError) { proco.submit :not_yet }
#   assert_raises(RuntimeError) { proco.exit }
#   assert_raises(RuntimeError) { proco.kill }

#   assert_raises(ArgumentError) {
#     proco.start
#   }

#   proco.start do |batch|
#     # Batch-process items every 0.1 seconds
#     # ...
#     puts "#{Thread.current}: #{batch}"
#     batch.length
#   end

#   assert_equal true, proco.running?

#   # Synchronous submit
#   50.times do |i|
#     result = proco.submit i
#     assert_instance_of Hash, result

#     assert result.has_key? :elapsed
#     assert result[:success]
#     assert_instance_of Fixnum, result[:return]
#   end

#   # Asynchronous submit
#   futures = 50.times.map { |i|
#     proco.submit! i, i ** 2, i ** 3
#   }
#   futures.each do |future|
#     assert_instance_of Proco::Future, future
#   end

#   # Wait until the batch containing the item is processed (FIXME: deadlock)
#   assert_equal 150, futures.uniq.map { |f| f.get[:return] }.inject(:+)

#   proco.exit
#   assert_equal false, proco.running?
# end

  def test_tries
    {
      1 => 0,
      2 => 0,
      3 => 1000,
      4 => 1000
    }.each do |t, exp|
      proco = Proco.tries(t).queue_size(900).new
      tries = {}
      cnt = 0
      proco.start do |items|
        tries[items] ||= 0
        tries[items] += 1

        if tries[items] < 3
          raise RuntimeError
        else
          cnt += items.length
          true
        end
      end

      1000.times do |i|
        proco.submit! i
      end

      proco.exit

      assert_equal exp, cnt
    end
  end

  def test_kill
    proco = Proco.new
    cnt = 0
    proco.start do |items|
      cnt += items.length
    end
    100.times do |i|
      proco.submit! i
    end
    proco.exit
    assert_equal 100, cnt

    cnt = 0
    proco.start do |items|
      sleep 5
      cnt += items.length
    end
    100.times do |i|
      proco.submit! i
    end
    proco.kill
    assert_equal 0, cnt
  end
end
