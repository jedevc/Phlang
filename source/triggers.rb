require_relative 'message'

def rmatch(regex, data)
    begin
        return Regexp.new(regex).match(data)
    rescue RegexpError
        return nil
    end
end

class TriggerData
    attr_reader :rmatches
    def initialize(rmatches)
        @rmatches = rmatches
    end
end

class Triggers
    public
    def self.trigger(rtype, data, bot, &blk)
        @@key[rtype].call(data, bot, blk)
    end

    def self.keys
        return @@key.keys
    end

    private
    def self.trigger_msg(data, bot, callback)
        bot.connection_event("send-event") do |m, r|
            message = Message.new(m)
            reg = rmatch(data.join, message.content)
            if reg
                callback.call(TriggerData.new(reg), message, r, bot)
            end
        end
    end

    def self.trigger_receive(data, bot, callback)
        bot.broadcast_event do |m, r|
            message = Message.new(m, "bot", nil, Time.now.to_i)
            reg = rmatch(data.join, message.content)
            if reg
                callback.call(TriggerData.new(reg), message, r, bot)
            end
        end
    end

    def self.trigger_timer(data, bot, callback)
        bot.connection_event("send-event") do |m, r|
            message = Message.new(m)
            reg = rmatch(data.slice(1, data.length).join, message.content)
            if reg
                r.timer.onevent(Time.now + data[0].to_i) do
                    callback.call(TriggerData.new(reg), message, r, bot)
                end
            end
        end
    end

    @@key = {
        # "start" => StartTrigger.method(:new),
        "msg" => Triggers.method(:trigger_msg),
        "receive" => Triggers.method(:trigger_receive),
        "timer" => Triggers.method(:trigger_timer),
        # "ptimer" => Triggers.method(:trigger_ptimer),
        # "every" => Trigger.method(:trigger_every)
    }
end

# class StartTrigger < Trigger
#     def add(bot, response)
#         bot.connection_event("snapshot-event") do |m, r|
#             trigger(response, Message.new(), r, bot)
#         end
#     end
#
#     def perform(response, args, message, room, bot)
#         response.call(nil, message, room, bot)
#     end
# end
#
# class PushTimerTrigger < Trigger
#     def initialize(*args)
#         super(*args)
#         @ending = {}
#         @last = {}
#     end
#
#     public
#     def add(bot, response)
#         bot.connection_event("send-event") do |m, r|
#             trigger(response, Message.new(m), r, bot)
#         end
#     end
#
#     def perform(response, args, message, room, bot)
#         reg = rmatch(args.slice(1, args.length).join, message.content)
#         if reg
#             if @ending.include?(room)
#                 @ending[room] = Time.now + args[0].to_i
#                 @last[room] = message
#             else
#                 add_time(room, args[0].to_i) do
#                     response.call(reg, @last[room], room, bot)
#                 end
#                 @last[room] = message
#             end
#         end
#     end
#
#     private
#     def add_time(room, delay, &blk)
#         @ending[room] = Time.now + delay
#         room.timer.onevent(@ending[room]) do
#             if @ending[room] < Time.now
#                 blk.call()
#                 @ending.delete(room)
#             else
#                 add_time(room, @ending[room] - Time.now, &blk)
#             end
#         end
#     end
# end
#
# class EveryTrigger < Trigger
#     def initialize(*args)
#         super(*args)
#
#         @counts = 0
#     end
#
#     def add(bot, response)
#         bot.connection_event("send-event") do |m, r|
#             trigger(response, Message.new(m), r, bot)
#         end
#     end
#
#     def perform(response, args, message, room, bot)
#         reg = rmatch(args.slice(1, args.length).join, message.content)
#         if reg
#             @counts += 1
#         end
#
#         if @counts >= args[0].to_i
#             response.call(reg, message, room, bot)
#             @counts = 0
#         end
#     end
# end
