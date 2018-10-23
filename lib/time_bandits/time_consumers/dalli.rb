# a time consumer implementation for memchached
# install into application_controller.rb with the line
#
#   time_bandit TimeBandits::TimeConsumers::Memcached
#

require "time_bandits/monkey_patches/client"

module TimeBandits
  module TimeConsumers
    class Dalli < BaseConsumer
      prefix :memcache
      fields :time, :calls, :misses, :reads, :writes, :key
      format "MC: %.3fms(%dr,%dm,%dw,%dc)", :time, :reads, :misses, :writes, :calls

      class Subscriber < ActiveSupport::LogSubscriber
        def get(event)
          i = Dalli.instance
          i.time += event.duration
          i.calls += 1
          payload = event.payload
          i.reads += payload[:reads]
          i.misses += payload[:misses]
          return unless logger.debug?
          message = event.payload[:misses] == 0 ? "Hit:" : "Miss:"
          logging(event,message) if logging_allowed?
        end
        def set(event)
          i = Dalli.instance
          i.time += event.duration
          i.calls += 1
          i.writes += 1
          return unless logger.debug?
          message = "Write:"
          logging(event,message) if logging_allowed?
        end

        private
        #The instrumentation logging is enabled via time_bandits verbose mode and it is default for development environment
        def logging(event,message)
          name = "%s (%.2fms)" % ["MemCache", event.duration]
          cmd = event.payload[:key]
          # output = "  #{color(name, CYAN, true)}"
          output = "  #{name}"
          output << " [#{message}#{cmd.to_s}]"
          debug output
        end
        def logging_allowed?
          ENV["TIME_BANDITS_VERBOSE"] = "true" if Rails.env.development?
          ENV["TIME_BANDITS_VERBOSE"] == "true" ? true : false
        end

      end
      Subscriber.attach_to :dalli
    end
  end
end