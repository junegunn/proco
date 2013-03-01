class Proco
module MT
# @private
module Base
  def initialize
    @mtx = Mutex.new
    @cv  = ConditionVariable.new
  end

  def try_when cond, &block
    return unless @mtx.try_lock

    begin
      block.call if cond.call
    ensure
      @cv.broadcast
      @mtx.unlock
    end
  end

  def do_when cond, &block
    @mtx.lock
    while !cond.call
      @cv.wait @mtx
    end
    block.call
  ensure
    # A good discussion on the use of broadcast instead of signal
    # http://stackoverflow.com/questions/37026/java-notify-vs-notifyall-all-over-again
    @cv.broadcast
    @mtx.unlock
  end

  def synchronize
    @mtx.synchronize do
      yield
    end
  end

  def wait_until &cond
    do_when(cond) {}
  end

  def signal &block
    @mtx.synchronize do
      begin
        block.call if block
      ensure
        @cv.signal
      end
    end
  end

  def broadcast &block
    @mtx.synchronize do
      begin
        block.call if block
      ensure
        @cv.broadcast
      end
    end
  end
end#Base
end#MT
end
