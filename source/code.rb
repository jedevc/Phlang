require_relative 'bot'

require_relative 'botbot_expression'

require_relative 'phlangbot'
require_relative 'room'

class Tokenizer
    attr_reader :tokens

    def initialize(raw)
        @raw = raw

        @tokens = []
        current = ''
        quote_open = false
        @raw.each_char do |c|
            if /\s/.match(c) && !quote_open
                if current.length > 0
                    @tokens.push(current)
                end
                current = ''
            elsif c == '"'
                quote_open = !quote_open
            else
                current += c
            end
        end

        if current.length > 0
            @tokens.push(current)
        end

        @rp = 0
    end

    def next()
        n = nil
        if @rp < @tokens.length
            n = @tokens[@rp]
        end
        @rp += 1
        return n
    end
end

class Response
    def initialize(args)
        @args = args
    end

    def do(trigdata, message, room, bot)
    end
end

module RegexBackreference
    def backrefs(rmatch, msg)
        (rmatch.length-1).times do |i|
            msg = msg.gsub("\\#{i+1}", rmatch[i+1])
        end
        return msg
    end
end

class BotbotResponse < Response
    def initialize(args)
        super(args)
        @exp = botbot_expression(@args.join(" "))
    end
end

class SendResponse < BotbotResponse
    include RegexBackreference

    def do(trigdata, message, room, bot)
        @exp.get.each do |msg|
            if msg.length > 0
                room.send_message(backrefs(trigdata, msg))
            end
        end
    end
end

class ReplyResponse < BotbotResponse
    include RegexBackreference

    def do(trigdata, message, room, bot)
        @exp.get.each do |msg|
            if msg.length > 0
                room.send_message(backrefs(trigdata, msg), message["id"])
            end
        end
    end
end

class NickResponse < BotbotResponse
    include RegexBackreference

    def do(trigdata, message, room, bot)
        nick = @exp.get[0]
        room.send_nick(backrefs(trigdata, nick))
    end
end

class CreateResponse < Response
    include RegexBackreference

    def do(trigdata, message, room, bot)
        nick = backrefs(trigdata, @args[0])
        code = backrefs(trigdata, @args.slice(1, @args.length).join(" "))
        nb = PhlangBot.new(nick, code, ADMIN_CONFIG, message["sender"]["name"])
        r = Room.new(room.name)
        nb.add_room(r)
        bot.group.add(nb)
    end
end

RESPONSES = {"send" => lambda do |args| return SendResponse.new(args) end,
             "reply" => lambda do |args| return ReplyResponse.new(args) end,
             "nick" => lambda do |args| return NickResponse.new(args) end,
             "create" => lambda do |args| return CreateResponse.new(args) end
}

class Trigger
    def initialize(args)
        @args = args
    end

    def add(bot, response)
    end
end

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

class Block
    def initialize()
        @trigger = nil
        @responses = []
    end

    def add_trigger(trigger, targs)
        @trigger = [trigger, targs]
    end

    def add_response(response, rargs)
        @responses.push([response, rargs])
    end

    def export()
        trig = TRIGGERS[@trigger[0]].call(@trigger[1])

        resps = []
        @responses.each do |r|
            resp, args = r
            resps.push(RESPONSES[resp].call(args))
        end

        return [trig, lambda do |d, m, r, b| resps.each do |f| f.do(d, m, r, b) end end]
    end
end

class CodeParser
    def initialize(raw)
        @raw = raw
    end

    def parse()
        blocks = []
        block = Block.new()

        trigger = []
        response = []

        tokens = Tokenizer.new(@raw)
        bit = tokens.next

        while bit
            if TRIGGERS.include?(bit)
                if response.length > 0
                    block.add_response(response[0], response.slice(1, response.length))
                    response = []
                end

                if trigger.length > 0
                    block.add_trigger(trigger[0], trigger.slice(1, trigger.length))
                    trigger = []

                    blocks.push(block)
                    block = Block.new()
                end
                trigger.push(bit)
            elsif RESPONSES.include?(bit)
                if response.length > 0
                    block.add_response(response[0], response.slice(1, response.length))
                    response = []
                end
                response.push(bit)
            else
                if response.length > 0
                    response.push(bit)
                elsif trigger.length > 0
                    trigger.push(bit)
                end
            end

            bit = tokens.next
        end

        # Add remaining bits at the end

        if trigger.length > 0
            block.add_trigger(trigger[0], trigger.slice(1, trigger.length))
        end

        if response.length > 0
            block.add_response(response[0], response.slice(1, response.length))
        end

        blocks.push(block)

        return blocks
    end
end
