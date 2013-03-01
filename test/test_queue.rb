$VERBOSE = true
require 'rubygems'
require 'minitest/autorun'
require 'proco'
require 'lps'

class TestQueue < MiniTest::Unit::TestCase
  def test_multi_queue
    queue = Proco::Queue::MultiQueue.new(200)
    futures = []
    num_batches = 0
    num_items = 0

    t1 = Thread.new {
      1000.times do |i|
        futures << queue.push(i)
      end
      queue.invalidate
    }

    t2 = Thread.new {
      future = items = nil
      begin
        LPS.freq(10).while { future, items = queue.take; future }.loop do
          num_batches += 1
          num_items   += items.length

          future.update(items) do
            items.length
          end
        end
      rescue Exception => e
        p e.backtrace
      end
    }

    t1.join
    t2.join

    assert_equal 1000, futures.length
    assert_equal num_batches, futures.uniq.length
    assert_equal 1000, num_items
    assert_equal 1000, futures.uniq.map { |future| future.get }.inject(:+)
  end
end
