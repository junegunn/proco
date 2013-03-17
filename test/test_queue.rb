$VERBOSE = true
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__) if $0 == __FILE__
require 'rubygems'
require 'minitest/autorun'
require 'proco'
require 'lps'

class TestQueue < MiniTest::Unit::TestCase
  def test_single_queue
    q = Proco::Queue::SingleQueue.new 100, nil
    fu1 = q.push 1
    assert_instance_of Proco::Future, fu1
    fu2 = q.push 2

    f2, i = q.take
    assert_equal fu1, f2
    assert_equal 1, i

    f3, i = q.take
    assert_equal 2, i
    assert_equal fu2, f3
  end

  def test_batch_queue
    q = Proco::Queue::BatchQueue.new 100, 10, nil

    futures = 10.times.map { |i| q.push i }
    assert_equal 1, futures.uniq.length

    future = futures.first
    future2 = q.push :next
    assert future != future2

    f, items = q.take
    assert_equal future, f
    assert_equal 10.times.to_a, items

    f, items = q.take
    assert_equal future2, f
    assert_equal [:next], items

    f = q.push :next
    assert future2 != f
  end

  def test_multi_queue
    q = Proco::Queue::MultiQueue.new 100, nil
    f1 = q.push 1
    f2 = q.push 2
    f3 = q.push 3
    assert_equal f1, f2
    assert_equal f2, f3

    f4, items = q.take
    assert_equal f3, f4
    assert_equal [1, 2, 3], items

    f5 = q.push 4
    assert ! f4 != f5

    f6, items = q.take
    assert_equal f5, f6
    assert_equal [4], items
  end

  def test_multi_queue_complex
    queue = Proco::Queue::MultiQueue.new(200, nil)
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
        LPS.freq(10).while {
          future, items = queue.take
          future
        }.loop do
          num_batches += 1
          num_items   += items.length

          future.update do
            items.length
          end
        end
      rescue Exception => e
        puts e
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
