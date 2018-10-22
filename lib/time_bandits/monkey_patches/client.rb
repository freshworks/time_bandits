# Add this line to your ApplicationController (app/controllers/application_controller.rb)
# to enable logging for memcached:
# time_bandit TimeBandits::TimeConsumers::Client

require 'dalli'

raise "Client needs to be loaded before monkey patching it" unless defined?(Dalli)


module Dalli
  class Client
    def get_with_benchmark(key, options=nil)
      ActiveSupport::Notifications.instrument("get.dalli") do |payload|
        if key.is_a?(Array)
          payload[:reads] = (num_keys = key.size)
          results = []
          begin
            results = get_without_benchmark(key, options)
          rescue Dalli::NotFound
          end
          payload[:misses] = num_keys - results.size
          results
          #binding.pry
        else
          val = nil
          payload[:reads] = 1
          payload[:misses] = 0
          begin
            val = get_without_benchmark(key, options)
          rescue Dalli::NotFound
          end
          payload[:misses] = 1  if val.is_a? NullObject
          payload[:key] = key
          val
          binding.pry
        end
      end
    end
    alias_method :get_without_benchmark, :get
    alias_method :get, :get_with_benchmark

    def set_with_benchmark(*args)
      ActiveSupport::Notifications.instrument("set.dalli") do
        set_without_benchmark(*args)
      end
    end
    alias_method :set_without_benchmark, :set
    alias_method :set, :set_with_benchmark
  end
end
