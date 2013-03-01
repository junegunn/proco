#!/usr/bin/env ruby

$VERBOSE = true
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'proco'
require 'benchmark'
require 'parallelize'
require 'thread'
require 'logger'

logger = Logger.new($stdout)
times = 1_000_000

Benchmark.bm(40) do |x|
  x.report('simple loop') do
    times.times do |i|
      Proco::Future.new
    end
  end

  x.report('Queue push and pop') do
    q = Queue.new
    times.times do |i|
      q.push Proco::Future.new
      q.pop
    end
  end

  x.report('Mutex synchronization') do
    m = Mutex.new
    a = []
    times.times do |i|
      m.synchronize do
        a << Proco::Future.new
      end
      m.synchronize do
        a.shift
      end
    end
  end

  x.report('Proco queue') do
    q = Proco::Queue::SingleQueue.new 100
    times.times do |i|
      q.push i
      q.take
    end
  end

  x.report('Default Proco') do
    proco = Proco.new
    proco.start do |item|
      nil
    end

    times.times do |i|
      print '.' if i % 1000 == 0
      proco.submit! i
    end
    proco.exit
  end

  [1, 4, 16].each do |queues|
    [1, 2, 4].each do |threads|
      x.report("q: #{queues}, t: #{threads}") do
        proco = Proco.queues(queues).logger(logger).threads(8).new
        proco.start do |items|
          nil
        end
        threads = 1
        parallelize(threads) do
          (times / threads).times do |i|
            print '.' if i % 1000 == 0
            proco.submit! i
          end
        end
        proco.kill
      end
    end
  end
end
