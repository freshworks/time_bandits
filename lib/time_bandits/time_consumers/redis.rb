# a time consumer implementation for redis
# install into application_controller.rb with the line
#
#   time_bandit TimeBandits::TimeConsumers::Redis
#
require 'time_bandits/monkey_patches/redis'

module TimeBandits
  module TimeConsumers
    class Redis < BaseConsumer
      prefix :redis
      fields :time, :calls
      format "Redis: %.3fms(%dc)", :time, :calls

      class Subscriber < ActiveSupport::LogSubscriber
        def request(event)
          i = Redis.instance
          i.time += event.duration
          i.calls += 1 #count redis round trips, not calls
          name = "%s (%.2fms)" % ["Redis", event.duration]
          cmds = event.payload[:commands]

          # output = "  #{color(name, CYAN, true)}"
          output = "  #{name}"

          cmds.each do |cmd, *args|
            if args.present?
              logged_args = args.map do |a|
                case
                when a.respond_to?(:inspect) then a.inspect
                when a.respond_to?(:to_s)    then a.to_s
                else
                  # handle poorly-behaved descendants of BasicObject
                  klass = a.instance_exec { (class << self; self end).superclass }
                  "\#<#{klass}:#{a.__id__}>"
                end
              end

              output << " [ #{cmd.to_s.upcase} #{logged_args.join(" ")} ]"
            else
              output << " [ #{cmd.to_s.upcase} ]"
            end
          end
          # to verify whether logging is permissible
          debug output if logging_allowed?
        end

        private

        #The Logging can be enabled in verbose mode and it is default for development environment
        # The debug logs are printed only for the foreground jobs and for the background jobs with job id.
        # Because the log lines increases exponentially for the background jobs while doing redis calls for the
        # presence of message in sidekiq job queues

        def logging_allowed?
          (!::Sidekiq.server? || (::Sidekiq.server? && Thread.current[:message_uuid])) && ENV["TIME_BANDITS_VERBOSE"] == "true" ? true : false
        end
      end
      Subscriber.attach_to(:redis)
    end
  end
end
