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
    def trigger(data, room, &blk)
    end
end

class StartTrigger < Trigger
    def trigger(data, room, &blk)
        room.connection.onevent("snapshot-event") do |_|
            blk.call(TriggerData.new, Message.new())
        end
    end
end

class MsgTrigger < Trigger
    def trigger(data, room, &blk)
        room.connection.onevent("send-event") do |packet|
            message = Message.new(packet)
            reg = rmatch(data.join, message.content)
            if reg
                blk.call(TriggerData.new(reg), message)
            end
        end
    end
end

class BroadcastTrigger < Trigger
    def trigger(data, room, &blk)
        room.broadcast.onevent do |message|
            message = Message.new(message, "bot", nil, Time.now.to_i)
            reg = rmatch(data.join, message.content)
            if reg
                blk.call(TriggerData.new(reg), message)
            end
        end
    end
end

class TimerTrigger < Trigger
    def trigger(data, room, &blk)
        room.connection.onevent("send-event") do |packet|
            message = Message.new(packet)
            reg = rmatch(data.slice(1, data.length).join, message.content)
            if reg
                room.timer.onevent(Time.now + data[0].to_i) do
                    blk.call(TriggerData.new(reg), message)
                end
            end
        end
    end
end

class PushTimerTrigger < Trigger
    def initialize()
        @ending = nil
        @last = nil
    end

    def trigger(data, room, &blk)
        room.connection.onevent("send-event") do |packet|
            message = Message.new(packet)
            reg = rmatch(data.slice(1, data.length).join, message.content)
            if reg
                @last = [TriggerData.new(reg), message]

                if @ending.nil?
                    add_time(room, data[0].to_i) do
                        blk.call(@last[0], @last[1])
                    end
                else
                    @ending = Time.now + data[0].to_i
                end
            end
        end
    end

    private
    def add_time(room, delay, &blk)
        @ending = Time.now + delay
        room.timer.onevent(Time.now + delay) do
            if @ending < Time.now
                blk.call()
                @ending = nil
            else
                add_time(room, @ending - Time.now, &blk)
            end
        end
    end
end

class EveryTrigger < Trigger
    def initialize()
        @count = 0
    end

    def trigger(data, room, &blk)
        room.connection.onevent("send-event") do |packet|
            message = Message.new(packet)
            reg = rmatch(data.slice(1, data.length).join, message.content)
            if reg
                @count += 1
            end

            if @count >= data[0].to_i
                blk.call(TriggerData.new(reg), message)
                @count = 0
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
