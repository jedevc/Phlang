require_relative 'code'

require_relative 'message'

class StartTrigger < Trigger
    def add(bot, response)
        bot.connection_event("snapshot-event") do |m, r|
            next trigger(response, Message.new(), r, bot)
        end
    end

    def perform(response, args, message, room, bot)
        response.call(nil, message, room, bot)
        return true
    end
end

class MessageTrigger < Trigger
    def add(bot, response)
        bot.connection_event("send-event") do |m, r|
            next trigger(response, Message.new(m), r, bot)
        end
    end

    def perform(response, args, message, room, bot)
        reg = Regexp.new(args.join).match(message.content)
        if reg
            response.call(reg, message, room, bot)
            return true
        else
            return false
        end
    end
end

class BroadcastTrigger < Trigger
    def add(bot, response)
        bot.broadcast_event do |m, r|
            next trigger(response, Message.new(m, "bot", Time.now.to_i), r, bot)
        end
    end

    def perform(response, args, message, room, bot)
        reg = Regexp.new(args.join).match(message.content)
        if reg
            response.call(reg, message, room, bot)
            return true
        else
            return false
        end
    end
end

class TimerTrigger < Trigger
    def add(bot, response)
        bot.connection_event("send-event") do |m, r|
            next trigger(response, Message.new(m), r, bot)
        end
    end

    def perform(response, args, message, room, bot)
        reg = Regexp.new(args.slice(1, args.length).join).match(message.content)
        if reg
            room.timer.onevent(Time.now + args[0].to_i) do
                response.call(reg, messag, room, bot)
            end
        end
        return false
    end
end

class PushTimerTrigger < Trigger
    def initialize(*args)
        super(*args)
        @ending = {}
        @last = {}
    end

    public
    def add(bot, response)
        bot.connection_event("send-event") do |m, r|
            next trigger(response, Message.new(m), r, bot)
        end
    end

    def perform(response, args, message, room, bot)
        reg = Regexp.new(args.slice(1, args.length).join).match(message.content)
        if reg
            if @ending.include?(room)
                @ending[room] = Time.now + args[0].to_i
                @last[room] = message
            else
                add_time(room, args[0].to_i) do
                    response.call(reg, @last[room], room, bot)
                end
                @last[room] = message
            end
        end
        return false
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
    def initialize(*args)
        super(*args)

        @counts = 0
    end

    def add(bot, response)
        bot.connection_event("send-event") do |m, r|
            next trigger(response, Message.new(m), r, bot)
        end
    end

    def perform(response, args, message, room, bot)
        reg = Regexp.new(args.slice(1, args.length).join).match(message.content)
        if reg
            @counts += 1
        end

        if @counts >= args[0].to_i
            response.call(reg, message, room, bot)
            @counts = 0
        end
        return false
    end
end
