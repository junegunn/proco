class Proco
class Dispatcher
  include Proco::MT::Threaded

  def initialize proco, thread_pool, block
    super()

    @tries, interval, qs =
      proco.options.values_at :tries, :interval, :queue_size
    @queue = Proco::Queue.new(qs)
    @pool  = thread_pool
    @block = block

    spawn do
      future = items = nil
      LPS.interval(interval).while {
        future, items = @queue.take_all
        future
      }.loop do
        inner_loop future, items
      end
    end
  end

  def push *items
    @queue.push *items
  end

  def exit
    @queue.invalidate
    super
  end

private
  def inner_loop future, items
    @pool.assign do
      future.send(:update) do
        ret = nil
        @tries.times do |i|
          begin
            ret = @block.call items
            break
          rescue Exception
            next if (i + 1) < @tries
            raise
          end
        end
        ret
      end
    end

    future
  end
end#Dispatcher
end#Proco
