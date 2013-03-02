class Proco
module MT
# @private
class Pool
  include Proco::Logger

  def initialize size, logger = nil
    @logger = logger
    @workers = size.times.map { |i|
      Worker.new @logger
    }
    @num_workers = @workers.length
    if @num_workers > 1
      self.instance_eval do
        alias assign assign_try
      end
    else
      self.instance_eval do
        alias assign assign_wait
      end
    end
  end

  def assign_wait &block
    # Optimistic randomized assignment to avoid mutex contention
    @workers.sample.assign(&block)
  end

  def assign_try &block
    @num_workers.times do |i|
      ret = @workers.sample.try_assign(&block)
      return ret if ret
    end
    # phew. blocking assignment
    # debug "Failed immediate thread allocation in the 1st round (#@num_workers)"
    assign(&block)
  end

  def exit
    @workers.each(&:exit)
  end

  def kill
    @workers.each(&:kill)
  end

  def counter
    @workers.map(&:counter).inject(:+)
  end
end#Pool
end#MT
end#Proco

