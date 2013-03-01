class Proco
module MT
# @private
class Worker
  include Proco::MT::Threaded

  attr_reader :counter

  def initialize logger
    super()

    @logger = logger
    @block = nil
    @counter = 0

    spawn do
      work while running?
    end
  end

  def work
    @mtx.lock
    while true
      return unless running?
      break if @block
      @cv.wait @mtx
    end
    @block.call
    @counter += 1
    @block = nil
  ensure
    @cv.broadcast
    @mtx.unlock
  end

  # Blocks when working
  def assign &block
    do_when(Proc.new { return unless running?; @block.nil? }) do
      @block = block
    end
  end

  # Returns nil when working
  def try_assign &block
    try_when(Proc.new { return unless running?; @block.nil? }) do
      @block = block
    end
  end

  def exit
    wait_until { @block.nil? }
    super
  end
end#Worker
end#MT
end#Proco
