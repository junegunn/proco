class Proco
module MT
class Worker
  include Proco::MT::Threaded

  attr_reader :counter

  def initialize
    super

    @block = nil
    @counter = 0

    spawn do
      while running?
        do_when(proc { break unless running?; @block }) do
          @block.call
          @counter += 1
          @block = nil
        end
      end
    end
  end

  # Blocks when working
  def assign &block
    do_when(proc { return unless running?; @block.nil? }) do
      @block = block
    end
  end

private
  def spawn_init

  end
end#Worker
end#MT
end#Proco
