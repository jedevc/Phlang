require_relative 'code'

class StartTrigger < Trigger
    def add(bot, response)
        bot.start_handle do |r|
            response.call([], {}, r, bot)
            next true
        end
    end
end

class MessageTrigger < Trigger
    def add(bot, response)
        bot.msg_handle do |m, r|
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
        if @args.length >= 2
            bot.msg_handle do |m, r|
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
end

class PushTimerTrigger < Trigger
    def initialize(args)
        super(args)
        @ending = {}
        @last = {}
    end

    public
    def add(bot, response)
        if @args.length >= 2
            bot.msg_handle do |m, r|
                reg = Regexp.new(@args.slice(1, @args.length).join).match(m["content"])
                if reg
                    if @ending.include?(r)
                        @ending[r] = Time.now + @args[0].to_i
                        @last[r] = m
                    else
                        add_time(r, @args[0].to_i) do
                            response.call(reg, @last[r], r, bot)
                        end
                        @last[r] = m
                    end
                end
                next false
            end
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
end
