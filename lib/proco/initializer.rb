class Proco
  class << self
    # @param [Numeric] i
    # @return [Proco]
    def interval i
      Proco.new :interval => i
    end

    # @param [Fixnum] t
    # @return [Proco]
    def threads t
      Proco.new :threads => t
    end

    # @param [Fixnum] r
    # @return [Proco]
    def tries r
      Proco.new :tries => r
    end

    # @param [Fixnum] q
    # @return [Proco]
    def queues q
      Proco.new :queues => q
    end

    # @param [Fixnum] qs
    # @return [Proco]
    def queue_size qs
      Proco.new :queue_size => qs
    end

    # @return [Proco]
    def batch b
      Proco.new :batch => b
    end
  end

  # @param [Numeric] i
  # @return [Proco]
  def interval i
    check_not_running
    Proco.new @options.merge(:interval => i)
  end

  # @param [Fixnum] t
  # @return [Proco]
  def threads t
    check_not_running
    Proco.new @options.merge(:threads => t)
  end

  # @param [Fixnum] r
  # @return [Proco]
  def tries r
    check_not_running
    Proco.new @options.merge(:tries => r)
  end

  # @param [Fixnum] q
  # @return [Proco]
  def queues q
    check_not_running
    Proco.new @options.merge(:queues => q)
  end

  # @param [Fixnum] qs
  # @return [Proco]
  def queue_size qs
    check_not_running
    Proco.new @options.merge(:queue_size => qs)
  end

  # @return [Proco]
  def batch b
    check_not_running
    Proco.new @options.merge(:batch => b)
  end

private
  def check_not_running
    raise RuntimeError, "Proco running" if running?
  end
end
