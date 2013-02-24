class Proco
class Dispatcher
  def initialize proco, interval, queue_size, thread_pool, block
    @queue = Proco::Queue.new(queue_size)
    @pool  = thread_pool
    @block = block
    @thread = Thread.new do
      LPS.interval(interval).while { proco.running? }.loop do
        p [:lps, Thread.current]
        inner_loop
      end
    end
  end

  def push *items
    @queue.push *items
  end

  def dispatch arg
  end

  def exit
    @queue.invalidate
    inner_loop
  end

private
  def inner_loop
    future, items = @queue.take_all
    return if items.nil? || items.empty?

    future.send(:update) do
      ret = nil
      options[:tries].times do |i|
        begin
          ret = @block.call items
          break
        rescue Exception
          next if (i + 1) < options[:tries]
          raise
        end
      end
      ret
    end

    future
  end
end#Dispatcher
end#Proco
