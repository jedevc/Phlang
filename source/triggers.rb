require_relative 'code'

class StartTrigger < Trigger
    def add(bot, response)
        bot.connection_event("snapshot-event") do |m, r|
            next trigger(response, {}, r, bot)
        end
    end

    def perform(response, args, packet, room, bot)
        response.call(nil, packet, room, bot)
        return true
    end
end

class MessageTrigger < Trigger
    def add(bot, response)
        bot.connection_event("send-event") do |m, r|
            next trigger(response, m, r, bot)
        end
    end

    def perform(response, args, packet, room, bot)
        reg = Regexp.new(args.join).match(packet["content"])
        if reg
            response.call(reg, packet, room, bot)
            return true
        else
            return false
        end
    end
end

class TimerTrigger < Trigger
    def add(bot, response)
        bot.connection_event("send-event") do |m, r|
            next trigger(response, m, r, bot)
        end
    end

    def perform(response, args, packet, room, bot)
        reg = Regexp.new(args.slice(1, args.length).join).match(packet["content"])
        if reg
            room.timer.onevent(Time.now + args[0].to_i) do
                response.call(reg, packet, room, bot)
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
            next trigger(response, m, r, bot)
        end
    end

    def perform(response, args, packet, room, bot)
        reg = Regexp.new(@args.slice(1, @args.length).join).match(packet["content"])
        if reg
            if @ending.include?(room)
                @ending[room] = Time.now + @args[0].to_i
                @last[room] = packet
            else
                add_time(room, @args[0].to_i) do
                    response.call(reg, @last[room], room, bot)
                end
                @last[room] = packet
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
            next trigger(response, m, r, bot)
        end
    end

    def perform(response, args, packet, room, bot)
        reg = Regexp.new(args.slice(1, args.length).join).match(packet["content"])
        if reg
            @counts += 1
        end

        if @counts >= args[0].to_i
            response.call(reg, packet, room, bot)
            @counts = 0
        end
        return false
    end
end
