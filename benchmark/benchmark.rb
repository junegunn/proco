#!/usr/bin/env ruby

$VERBOSE = true
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'proco'
require 'benchmark'
require 'parallelize'
require 'logger'

logger = Logger.new($stdout)
range  = (1..1000)
times  = 5000
batch  = 100
task   = lambda do
  range.inject(:*)
end

Benchmark.bm(40) do |x|
  x.report('loop') do
    times.times do
      task.call
    end
  end

  x.report('default proco') do
    proco = Proco.new
    proco.start do
      task.call
    end
    times.times do |i|
      proco.submit! i
    end
    proco.exit
  end

  [2, 4, 8].each do |threads|
    x.report("parallelize (#{threads})") do
      parallelize(threads) do
        (times / threads).times do
          task.call
        end
      end
    end

    [1, 4].each do |queues|
      x.report("proco with #{threads} threads / #{queues} queues") do
        proco = Proco.queues(queues).threads(threads).new
        proco.start do
          task.call
        end
        times.times do |i|
          proco.submit! i
        end
        proco.exit
      end

      x.report("proco with #{threads} threads / #{queues} queues / batch submit") do
        proco = Proco.queues(queues).threads(threads).new
        proco.start do
          task.call
        end
        times.times.each_slice(100) do |is|
          proco.submit! *is
        end
        proco.exit
      end

      x.report("batch proco with #{threads} threads / #{queues} queues") do
        proco = Proco.queues(queues).threads(threads).batch(true).new
        proco.start do |items|
          items.length.times do
            task.call
          end
        end
        times.times do |i|
          proco.submit! i
        end
        proco.exit
      end
    end
  end
end
