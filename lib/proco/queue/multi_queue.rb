require 'thread'

class Proco
module Queue
# @private
class MultiQueue < Proco::Queue::Base
  def initialize size
    super
    @future = Future.new
  end

  def push_impl item
    @items << item
    @future
  end

  def take_impl
    items   = @items
    ret     = [@future, items]

    # Reset vars
    @items  = []
    @future = Future.new

    ret
  end
end
end
end

