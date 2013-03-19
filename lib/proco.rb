require 'proco/version'
require 'proco/logger'
require 'proco/mt/base'
require 'proco/mt/threaded'
require 'proco/mt/worker'
require 'proco/mt/pool'
require 'proco/dispatcher'
require 'proco/future'
require 'proco/queue/base'
require 'proco/queue/single_queue'
require 'proco/queue/batch_queue'
require 'proco/queue/multi_queue'
require 'option_initializer'
require 'set'

class Array
  def sample
    self[Kernel.rand(size)]
  end unless method_defined? :sample
end

class Proco
  include Proco::Logger
  include OptionInitializer

  option_initializer :logger,
                     :interval   => Numeric,
                     :threads    => Fixnum,
                     :queues     => Fixnum,
                     :queue_size => Fixnum,
                     :batch      => Set[true, false],
                     :batch_size => Fixnum
  option_validator do |opt, val|
    case opt
    when :interval
      raise ArgumentError, "#{opt} must be a non-negative number" if val < 0
    when :threads, :queues, :queue_size, :batch_size
      raise ArgumentError, "#{opt} must be a positive integer" if val <= 0
    end
  end

  attr_reader :options

  DEFAULT_OPTIONS = {
    :interval   => 0,
    :threads    => 1,
    :queues     => 1,
    :queue_size => 1000,
    :batch_size => 100,
    :batch      => false
  }

  def initialize options = {}, &processor
    validate_options options
    @options = DEFAULT_OPTIONS.merge(options)
    @logger = @options[:logger]

    @pool = nil
    @running = false
  end

  # @return [Proco]
  def start &block
    raise ArgumentError, "Block not given" if block.nil?
    @running = true
    @pool = Proco::MT::Pool.new(options[:threads], @logger)
    @dispatchers = options[:queues].times.map { |i|
      Dispatcher.new(self, @pool, block)
    }

    self
  end

  # Synchronous submission
  # @param [Object] items
  # @return [Hash]
  def submit item
    check_running
    submit!(item).get
  end

  # Asynchronous submission
  # @param [Object] items
  # @return [Proco::Future]
  def submit! item
    check_running
    @dispatchers.sample.push(item)
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
    @dispatchers.each(&:kill)
    @pool.kill
    nil
  end

  # @return [Boolean]
  def running?
    @running
  end

private
  def check_running
    raise RuntimeError, "Not running" unless running?
  end
end

