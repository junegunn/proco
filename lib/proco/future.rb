class Proco
class Future
  include Proco::MT::Base

  def get
    do_when(proc { @status != :wait }) do
      if @status == :ok
        return @return
      else
        raise @return
      end
    end
  end

  def inspect
    "Future=#{@status}"
  end

  # @private
  def initialize
    super()
    @status = :wait
    @return = nil
  end

  # @private
  def update
    begin
      @return = yield
      @status = :ok
    rescue Exception => e
      @return = e
      @status = :fail
    end

    broadcast
  end
end
end

