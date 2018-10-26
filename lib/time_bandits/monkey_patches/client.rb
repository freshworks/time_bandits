# Add this line to your ApplicationController (app/controllers/application_controller.rb)
# to enable logging for memcached:
# time_bandit TimeBandits::TimeConsumers::DalliCustom

require 'dalli'

raise "Dalli needs to be loaded before monkey patching it" unless defined?(Dalli)


module Dalli
  class Client
    def get_with_benchmark(key, options=nil)
      ActiveSupport::Notifications.instrument("get.dalli") do |payload|
        if key.is_a?(Array)
          payload[:reads] = (num_keys = key.size)
          results = []
          results = get_without_benchmark(key, options)
          payload[:misses] = num_keys - results.size
          results
        else
          val = nil
          payload[:reads] = 1
          payload[:misses] = 0
          val = get_without_benchmark(key, options)
          payload[:misses] = 1  if val.is_a?(NullObject) || val.blank?
          payload[:key] = key
          val
        end
      end
    end

    alias_method :get_without_benchmark, :get
    alias_method :get, :get_with_benchmark

    def set_with_benchmark(*args)
      ActiveSupport::Notifications.instrument("set.dalli") do |payload|
        payload[:key] = args[0]
        set_without_benchmark(*args)
      end
    end

    alias_method :set_without_benchmark, :set
    alias_method :set, :set_with_benchmark

  end
end
