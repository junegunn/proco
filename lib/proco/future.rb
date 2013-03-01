class Proco
class Future
  include Proco::MT::Base

  # NOTE unordered
  class GroupReturn < Exception
    attr_reader :returns

    def initialize returns
      @returns = returns
    end

    def to_s
      "exception thrown"
    end

    def to_h
      @returns
    end
  end

  def get
    do_when(proc { @done == @count }) do
      if @fail
        if @count == 1
          raise @returns.values.first
        else
          raise GroupReturn.new(@returns)
        end
      else
        if @count == 1
          @returns.values.first
        else
          @returns
        end
      end
    end
  end

  def inspect
    "Future=#{@status.inspect}"
  end

  # @private
  def initialize count
    super()
    @count   = count
    @done    = 0
    @fail    = false
    @returns = {}
  end

  # @private
  def update items
    ret =
      begin
        yield
      rescue Exception => e
        @fail = true # no sync required
        e
      end

    broadcast do
      @returns[items] = ret
      @done += 1
    end
  end
end
end

