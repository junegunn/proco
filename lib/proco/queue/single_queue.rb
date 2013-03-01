require 'thread'

class Proco
module Queue
# @private
class SingleQueue < Proco::Queue::Base
  def initialize size = nil
    super
  end

  def push_impl items
    future = Future.new(items.length)
    tuples = items.map { |item| [future, item] }
    @items.concat tuples
    future
  end

  def take_impl
    @items.shift
  end
end
end
end

