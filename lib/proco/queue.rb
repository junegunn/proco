require 'thread'

class Proco
# @private
class Queue
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
    @future = Future.new
  end

  def push *items
    do_when(proc {
      raise Invalidated unless @valid
      !@size || (@items.length + items.length) <= @size
    }) do
      @items.concat items
      @future
    end
  end

  def take_all
    do_when(proc {
      empty = @items.empty?
      return nil if empty && !@valid
      !empty
    }) do
      items   = @items
      ret     = [@future, items]

      # Reset vars
      @items  = []
      @future = Future.send(:new)

      ret
    end
  end

  def invalidate
    signal do
      @valid = false
    end
  end
end
end

