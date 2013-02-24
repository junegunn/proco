class Proco
class Future
  include Proco::MT::Base

  def get
    do_when(proc { @done }) do
      if @status[:exception]
        raise @status[:exception]
      else
        @status
      end
    end
  end

  def inspect
    "Future=#{@status.inspect}"
  end

private
  def initialize
    super()
    @done = false
    @status = { :success => false }
  end

  # @private
  def update
    st = Time.now
    begin
      @status[:return] = yield
      @status[:success] = true
    rescue Exception => e
      @status[:exception] = e
    end
    @status[:elapsed] = Time.now - st
    @done = true

    broadcast
  end
end
end

