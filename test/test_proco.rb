$VERBOSE = true
require 'rubygems'
require 'minitest/autorun'
require 'proco'

class TestProco < MiniTest::Unit::TestCase
  def test_proco_lifecycle
    proco = Proco.interval(0.1).threads(4).queues(8).queue_size(10)

    assert_equal false, proco.running?

    # No you can't submit an item yet
    assert_raises(RuntimeError) { proco.submit :not_yet }
    assert_raises(RuntimeError) { proco.exit }
    assert_raises(RuntimeError) { proco.kill }

    assert_raises(ArgumentError) {
      proco.start
    }

    proco.start do |batch|
      # Batch-process items every 0.1 seconds
      # ...
      puts "#{Thread.current}: #{batch}"
      batch.length
    end

    assert_equal true, proco.running?

    # Synchronous submit
    50.times do |i|
      result = proco.submit i
      assert_instance_of Hash, result

      assert result.has_key? :elapsed
      assert result[:success]
      assert_instance_of Fixnum, result[:return]
    end

    # Asynchronous submit
    futures = 50.times.map { |i|
      proco.submit! i, i ** 2, i ** 3
    }
    futures.each do |future|
      assert_instance_of Proco::Future, future
    end

    # Wait until the batch containing the item is processed
    assert_equal 150,   futures.uniq.map { |f| f.get[:return] }.inject(:+)

    proco.exit
    assert_equal false, proco.running?
  end

  def test_tries
    {
      1 => 0,
      2 => 0,
      3 => 1000,
      4 => 1000
    }.each do |t, exp|
      proco = Proco.tries(t).queue_size(900)
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
