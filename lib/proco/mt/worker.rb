class Proco
module MT
# @private
class Worker
  include Proco::MT::Threaded

  attr_reader :counter

  def initialize logger
    super()

    @logger  = logger
    @block   = nil
    @counter = 0

    spawn do
      work while running?
    end
  end

  def work
    # Not using do_when makes the code around the task block about 10% faster
    @mtx.lock
    while true
      return unless running?
      break if @block
      @cv.wait @mtx
    end
    block = @block
    @counter += 1
    @block = nil

    # Release lock here, so that a new task can be assigned during the execution
    # 50 -> 30
    @cv.broadcast
    @mtx.unlock

    # Work!
    block.call
  end

  # Blocks when working
  def assign &block
    #do_when(Proc.new { return unless running?; @block.nil? }) do
    #  @block = block
    #end
    @mtx.lock
    while true
      return unless running?
      break unless @block
      @cv.wait @mtx
    end
    @block = block
  ensure
    @cv.broadcast
    @mtx.unlock
  end

  # Returns nil when working
  def try_assign &block
    #try_when(Proc.new { return unless running?; @block.nil? }) do
    #  @block = block
    #end
    return unless @mtx.try_lock

    begin
      return if !running? || @block
      @block = block
    ensure
      @cv.broadcast
      @mtx.unlock
    end
  end

  def exit
    wait_until { @block.nil? }
    super
  end
end#Worker
end#MT
end#Proco
