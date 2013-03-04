require 'thread'

class Proco
module Queue
# @private
class BatchQueue < Proco::Queue::Base
  def initialize size, batch_size, delay
    super size, delay
    @futures = []
    @batch_size = batch_size
  end

  def push_impl item
    @items << item
    if @items.length % @batch_size == 1
      @futures << Future.new
    end
    @futures.last
  end

  def take_impl
    items  = @items[0, @batch_size]
    @items = @items[@batch_size..-1] || []

    [@futures.shift, items]
  end
end
end
end

