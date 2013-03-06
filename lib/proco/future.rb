class Proco
class Future
  include Proco::MT::Base

  def get
    do_when(proc { @state != :wait }) do
      if @state == :ok
        return @return
      else
        raise @return
      end
    end
  end

  def done?
    @state != :wait
  end

  def inspect
    "Future=#{@state}"
  end

  # @private
  def initialize
    super()
    @state = :wait
    @return = nil
  end

  # @private
  def update
    begin
      @return = yield
      @state = :ok
    rescue Exception => e
      @return = e
      @state = :fail
    end

    broadcast
  end
end
end

