require 'proco/version'
require 'proco/initializer'
require 'proco/mt/base'
require 'proco/mt/threaded'
require 'proco/mt/worker'
require 'proco/mt/pool'
require 'proco/dispatcher'
require 'proco/future'
require 'proco/queue'

class Proco
  attr_reader :options

  DEFAULT_OPTIONS = {
    :interval   => 0.1,
    :tries      => 1,
    :threads    => 1,
    :queues     => 1,
    :queue_size => 1000,
    :batch      => false
  }

  def initialize options = {}, &processor
    @options = DEFAULT_OPTIONS.merge(options)
    @pool = nil
    @running = false
  end

  # @return [Proco]
  def start &block
    raise ArgumentError, "Block not given" if block.nil?
    @running = true
    @pool = Proco::MT::Pool.new(options[:threads])
    @dispatchers = options[:queues].times.map { |i|
      Dispatcher.new(self, @pool, block)
    }

    self
  end

  # Synchronous submission
  # @return [Hash]
  def submit *items
    check_running
    submit!(*items).get
  end

  # Asynchronous submission
  # @param [*Object] items
  # @return [Proco::Future]
  def submit! *items
    check_running
    # TODO: sample in 1.8
    @dispatchers.sample.push(*items)
  end

  # Stops Proco, returns results from remaining submissions in the queue.
  # @return [nil]
  def exit
    check_running
    @running = false
    @dispatchers.each(&:exit)
    @pool.exit
  end

  # @return [nil]
  def kill
    check_running
    @running = false
    @pool.kill
    nil
  end

  # @return [Boolean]
  def running?
    @running
  end

private
  def check_options
    interval, threads, tries, qs =
      @options.values_at :interval, :threads, :tries, :queue_size

    if !interval.is_a?(Numeric) || interval < 0
      raise ArgumentError, "Invalid interval"
    end

    if !threads.is_a?(Fixnum) || threads <= 0
      raise ArgumentError, "Invalid threads"
    end

    if !tries.is_a?(Fixnum) || tries <= 0
      raise ArgumentError, "Invalid threads"
    end

    if !qs.is_a?(Fixnum) || qs <= 0
      raise ArgumentError, "Invalid queue_size"
    end
  end

  def check_running
    raise RuntimeError, "Not running" unless running?
  end
end

