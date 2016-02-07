require_relative 'code'

class MessageTrigger < Trigger
    def add(bot, response)
        bot.add_handle("send-event") do |m, r|
            reg = Regexp.new(@args.join(" ")).match(m["content"])
            if reg
                response.call(reg, m, r, bot)
                next true
            else
                next false
            end
        end
    end
end

class TimerTrigger < Trigger
    def add(bot, response)
        bot.add_handle("send-event") do |m, r|
            reg = Regexp.new(@args.slice(1, @args.length).join).match(m["content"])
            if reg
                r.intime(@args[0].to_i) do
                    response.call(reg, m, r, bot)
                end
            end
            next false
        end
    end
end

class PushTimerTrigger < Trigger
    def initialize(args)
        super(args)
        @ending = {}
    end

    public
    def add(bot, response)
        bot.add_handle("send-event") do |m, r|
            reg = Regexp.new(@args.slice(1, @args.length).join).match(m["content"])
            if reg
                if @ending.include?(r)
                    push_time(r, @args[0].to_i)
                else
                    add_time(r, @args[0].to_i) do
                        response.call(reg, m, r, bot)
                    end
                end
            end
            next false
        end
    end

    private
    def add_time(room, delay, &blk)
        @ending[room] = Time.now + delay
        room.intime(delay) do
            if @ending[room] < Time.now
                blk.call()
                @ending.delete(room)
            else
                add_time(room, @ending[room] - Time.now, &blk)
            end
        end
    end

    def push_time(room, delay)
        if @ending.include?(room)
            @ending[room] = Time.now + delay
        end
    end
end

TRIGGERS = {"msg" => lambda do |args| return MessageTrigger.new(args) end,
            "timer" => lambda do |args| return TimerTrigger.new(args) end,
            "ptimer" => lambda do |args| return PushTimerTrigger.new(args) end
}
