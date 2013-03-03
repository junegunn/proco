#!/usr/bin/env ruby

$VERBOSE = true
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'proco'
require 'benchmark'
require 'parallelize'
require 'logger'

logger = Logger.new($stdout)

[:cpu, :directio].each do |mode|
  if mode == :cpu
    times = 20000
    # CPU Intensive task
    task = lambda do |item|
      (1..10000).inject(:+)
    end

    btask = lambda do |items|
      items.each do
        (1..10000).inject(:+)
      end
    end
  else
    mtx = Mutex.new

    times = 1000
    task = lambda do |item|
      mtx.synchronize do
        sleep 0.01 + 0.001
      end
    end

    btask = lambda do |items|
      mtx.synchronize do
        sleep 0.01 + 0.001 * items.length
      end
    end
  end

  result = Benchmark.bm(45) do |x|
    x.report("loop") do
      times.times do |i|
        task.call i
      end
    end

    x.report('Proco.new') do
      proco = Proco.new
      proco.start do |i|
        task.call i
      end
      times.times do |i|
        proco.submit! i
      end
      proco.exit
    end

    [2, 4, 8].each do |threads|
      x.report("parallelize(#{threads})") do
        parallelize(threads) do
          (times / threads).times do |i|
            task.call i
          end
        end
      end

      [1, 4].each do |queues|
        x.report("Proco.threads(#{threads}).queues(#{queues}).new") do
          proco = Proco.queues(queues).threads(threads).new
          proco.start do |i|
            task.call i
          end
          times.times do |i|
            proco.submit! i
          end
          proco.exit
        end

        x.report("Proco.threads(#{threads}).queues(#{queues}).batch(true).new") do
          proco = Proco.queues(queues).threads(threads).batch(true).new
          proco.start do |items|
            btask.call items
          end
          times.times do |i|
            proco.submit! i
          end
          proco.exit
        end
      end
    end
  end

  data = Hash[ result.map { |r| [r.label, r.real] } ]
  mlen = data.keys.map(&:length).max
  mval = data.values.max
  width = 40
  data.each do |k, v|
    puts k.ljust(mlen) + ' : ' + '*' * (width * (v / mval)).to_i
  end
  puts
end
