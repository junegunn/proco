require 'thread'

class Proco
module Queue
# @private
class MultiQueue < Proco::Queue::Base
  def initialize size = nil
    super
    @future = Future.new(1)
  end

  def push_impl items
    @items.concat items
    @future
  end

  def take_impl
    items   = @items
    ret     = [@future, items]

    # Reset vars
    @items  = []
    @future = Future.new(1)

    ret
  end
end
end
end

