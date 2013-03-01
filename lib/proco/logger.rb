require 'forwardable'

class Proco
module Logger
  extend Forwardable

  class DummyLogger
    [:info, :debug, :warn, :error].each do |m|
      define_method m do |msg|
      end
    end
  end

  def logger
    @logger ||= DummyLogger.new
  end

  def_delegators :logger, :info, :debug, :warn, :error
end#Logger
end#Proco

