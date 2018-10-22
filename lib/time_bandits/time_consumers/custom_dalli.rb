if Rails::VERSION::STRING =~ /\A4.[0123]/
  require "time_bandits/monkey_patches/active_support_cache_store"
end

module TimeBandits::TimeConsumers
  class CustomDalli < BaseConsumer
    prefix :memcache
    fields :time, :calls, :misses, :reads, :writes
    format "Dalli: %.3f(%dr,%dm,%dw,%dc)", :time, :reads, :misses, :writes, :calls

    if Rails::VERSION::STRING >= "4.0" && Rails::VERSION::STRING < "4.2" && Rails.cache.class.respond_to?(:instrument=)
      # Rails 4 mem_cache_store (which uses dalli internally), unlike dalli_store, is not instrumented by default
      def reset
        Rails.cache.class.instrument = true
        super
      end
    end

    class Subscriber < ActiveSupport::LogSubscriber
      # cache events are: read write fetch_hit generate delete read_multi increment decrement clear
      def cache_read(event)
        i = CustomDalli.instance
        i.time += event.duration
        i.calls += 1
        i.reads += 1
        i.misses += 1 unless event.payload[:hit]
        binding.pry
      end

      def cache_read_multi(event)
        i = CustomDalli.instance
        i.time += event.duration
        i.calls += 1
        i.reads += event.payload[:key].size
      end

      def cache_write(event)
        i = CustomDalli.instance
        i.time += event.duration
        i.calls += 1
        i.writes += 1
        #binding.pry
      end

      def cache_increment(event)
        i = CustomDalli.instance
        i.time += event.duration
        i.calls += 1
        i.writes += 1
      end

      def cache_decrement(event)
        i = CustomDalli.instance
        i.time += event.duration
        i.calls += 1
        i.writes += 1
      end

      def cache_delete(event)
        i = CustomDalli.instance
        i.time += event.duration
        i.calls += 1
        i.writes += 1
      end
    end
    Subscriber.attach_to :active_support
  end
end
