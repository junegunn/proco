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
    waited = false
    while true
      empty = @items.empty?
      unless empty
        if waited && @delay > 0
          # Haven't took anything.
          # No need to broadcast to blocked pushers
          @mtx.unlock
          sleep @delay
          @mtx.lock
        end
        break
      end
      return nil unless @valid
      @cv.wait @mtx
      waited = true
    end
    take_impl
  ensure
    @cv.broadcast
    @mtx.unlock
  end
end#Base
end#Queue
end


