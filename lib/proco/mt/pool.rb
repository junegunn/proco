class Proco
module MT
# @private
class Pool
  def initialize size
    @workers = size.times.map { |i|
      Worker.new
    }
  end

  def assign &block
    # Optimistic randomized assignment to avoid mutex contention
    @workers.sample.assign(&block)
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

