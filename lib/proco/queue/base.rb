require 'thread'

class Proco
module Queue
# @private
class Base
  include Proco::MT::Base

  class Invalidated < Exception
    def to_s
      "Queue invalidated"
    end
  end

  def initialize size, delay
    super()
    @size  = size
    @delay = delay || 0
    @items = []
    @valid = true
  end

  def invalidate
    broadcast do
      @valid = false
    end
  end

  def push item
    @mtx.lock
    while true
      raise Invalidated unless @valid
      break if @items.length < @size
      @cv.wait @mtx
    end
    push_impl item
  ensure
    @cv.broadcast
    @mtx.unlock
  end

  def take
    @mtx.lock
    wait_at = nil
    while true
      empty = @items.empty?
      unless empty
        if wait_at && @delay > 0
          s = (wait_at + @delay) - Time.now
          if s > 0
            # Haven't took anything.
            # No need to broadcast to blocked pushers
            @mtx.unlock
            sleep s
            @mtx.lock
          end
        end
        break
      end
      return nil unless @valid
      wait_at = Time.now
      @cv.wait @mtx
    end
    take_impl
  ensure
    @cv.broadcast
    @mtx.unlock
  end
end#Base
end#Queue
end


