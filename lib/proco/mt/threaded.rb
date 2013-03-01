class Proco
module MT
# @private
module Threaded
  include Proco::Logger
  include Proco::MT::Base

  def initialize
    super
    @running = false
  end

  def running?
    @running
  end

  def exit
    broadcast do
      @running = false
    end
    @thread.join
  end

  def kill
    @running = false
    Thread.kill @thread if @thread
  end

  def spawn &block
    @thread = Thread.new do
      debug "#{Thread.current} started (#{self})"
      broadcast do
        @running = true
      end

      begin
        block.call
      rescue Exception => e
        p e
        error "[#{Thread.current}] #{e}"
        raise
      ensure
        debug "#{Thread.current} exited (#{self})"
      end
    end
    wait_until { running? }

    @thread
  end
end#Threaded
end#MT
end#Proco

