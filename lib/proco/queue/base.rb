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

  def initialize size = nil
    super()
    @size   = size
    @items  = []
    @valid  = true
  end

  def invalidate
    signal do
      @valid = false
    end
  end

  def push *items
    do_when(Proc.new {
      raise Invalidated unless @valid
      !@size || (@items.length + items.length) <= @size
    }) do
      push_impl items
    end
  end

  def take
    do_when(Proc.new {
      empty = @items.empty?
      return nil if empty && !@valid
      !empty
    }) do
      take_impl
    end
  end
end#Base
end#Queue
end


