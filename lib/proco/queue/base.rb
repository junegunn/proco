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

  def initialize size
    super()
    @size   = size
    @items  = []
    @valid  = true
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
    while true
      empty = @items.empty?
      return nil if empty && !@valid
      break if !empty
      @cv.wait @mtx
    end
    take_impl
  ensure
    @cv.broadcast
    @mtx.unlock
  end

# def push *items
#   do_when(Proc.new {
#     raise Invalidated unless @valid
#     !@size || (@items.length + items.length) <= @size
#   }) do
#     push_impl items
#   end
# end

# def take
#   do_when(Proc.new {
#     empty = @items.empty?
#     return nil if empty && !@valid
#     !empty
#   }) do
#     take_impl
#   end
# end
end#Base
end#Queue
end


