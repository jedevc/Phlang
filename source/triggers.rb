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
    def initialize(rmatches=nil)
        @rmatches = rmatches
    end
end

class Trigger
    def trigger(data, bot, &blk)
    end
end

class StartTrigger < Trigger
    def trigger(data, bot, &blk)
        bot.connection_event("snapshot-event") do |m, r|
            blk.call(TriggerData.new, Message.new(), r, bot)
        end
    end
end

class MsgTrigger < Trigger
    def trigger(data, bot, &blk)
        bot.connection_event("send-event") do |m, r|
            message = Message.new(m)
            reg = rmatch(data.join, message.content)
            if reg
                blk.call(TriggerData.new(reg), message, r, bot)
            end
        end
    end
end

class BroadcastTrigger < Trigger
    def trigger(data, bot, &blk)
        bot.broadcast_event do |m, r|
            message = Message.new(m, "bot", nil, Time.now.to_i)
            reg = rmatch(data.join, message.content)
            if reg
                blk.call(TriggerData.new(reg), message, r, bot)
            end
        end
    end
end

class TimerTrigger < Trigger
    def trigger(data, bot, &blk)
        bot.connection_event("send-event") do |m, r|
            message = Message.new(m)
            reg = rmatch(data.slice(1, data.length).join, message.content)
            if reg
                r.timer.onevent(Time.now + data[0].to_i) do
                    blk.call(TriggerData.new(reg), message, r, bot)
                end
            end
        end
    end
end

class PushTimerTrigger < Trigger
    def initialize()
        @ending = {}
        @last = {}
    end

    def trigger(data, bot, &blk)
        bot.connection_event("send-event") do |m, r|
            message = Message.new(m)
            reg = rmatch(data.slice(1, data.length).join, message.content)
            if reg
                @last[r] = [TriggerData.new(reg), message]
                if @ending.include? r
                    @ending[r] = Time.now + data[0].to_i
                else
                    add_time(r, data[0].to_i) do
                        blk.call(@last[r][0], @last[r][1], r, bot)
                    end
                end
            end
        end
    end

    private
    def add_time(room, delay, &blk)
        @ending[room] = Time.now + delay
        room.timer.onevent(@ending[room]) do
            if @ending[room] < Time.now
                blk.call()
                @ending.delete(room)
            else
                add_time(room, @ending[room] - Time.now, &blk)
            end
        end
    end
end

class EveryTrigger < Trigger
    def initialize()
        @counts = {}
    end

    def trigger(data, bot, &blk)
        bot.connection_event("send-event") do |m, r|
            message = Message.new(m)
            reg = rmatch(data.slice(1, data.length).join, message.content)
            if reg
                if @counts.include? r
                    @counts[r] += 1
                else
                    @counts[r] = 1
                end
            end

            if @counts.include? r and @counts[r] >= data[0].to_i
                blk.call(TriggerData.new(reg), message, r, bot)
                @counts.delete(r)
            end
        end
    end
end

class Triggers
    public
    def self.trigger(rtype)
        return @@merged[rtype].call
    end

    def self.simple
        return @@simple.keys
    end

    @@simple = {
        "start" => StartTrigger.method(:new),
        "msg" => MsgTrigger.method(:new),
        "receive" => BroadcastTrigger.method(:new),
        "timer" => TimerTrigger.method(:new),
        "ptimer" => PushTimerTrigger.method(:new),
        "every" => EveryTrigger.method(:new)
    }

    @@merged = @@simple
end
