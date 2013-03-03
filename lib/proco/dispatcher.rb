require 'lps'

class Proco
# @private
class Dispatcher
  include Proco::MT::Threaded

  def initialize proco, thread_pool, block
    super()

    @logger, interval, qs, batch, batch_size =
      proco.options.values_at :logger, :interval, :queue_size, :batch, :batch_size
    @queue = if batch && batch_size
               Proco::Queue::BatchQueue.new(qs, batch_size)
             elsif batch
               Proco::Queue::MultiQueue.new(qs)
             else
               Proco::Queue::SingleQueue.new(qs)
             end
    @pool  = thread_pool
    @block = block

    spawn do
      future = items = nil
      LPS.interval(interval).while {
        future, items = @queue.take
        future # JRuby bug
      }.loop do
        inner_loop future, items
      end
    end
  end

  def push *items
    @queue.push(*items)
  end

  def exit
    @queue.invalidate
    super
  end

private
  def inner_loop future, items
    @pool.assign do
      future.update do
        begin
          @block.call items
        rescue Exception => e
          error e.to_s # TODO
          raise
        end
      end
    end

    future
  end
end#Dispatcher
end#Proco
