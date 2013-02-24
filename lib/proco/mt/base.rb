class Proco
module MT
# @private
module Base
  def initialize
    @mtx = Mutex.new
    @cv = ConditionVariable.new
    @running = nil
  end

  def do_when cond, &block
    @mtx.synchronize do
      begin
        while !cond.call
          @cv.wait @mtx
        end
        block.call
      ensure
        @cv.signal
      end
    end
  end

  def wait_until &cond
    do_when(cond) do
    end
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
