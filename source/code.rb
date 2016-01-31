require_relative 'bot'

require_relative 'botbot_expression'

class Tokenizer
    attr_reader :tokens

    def initialize(raw)
        @raw = raw

        @tokens = []
        current = ''
        quote_open = false
        @raw.each_char do |c|
            if /\s/.match(c) && !quote_open
                tokens.push(current)
                current = ''
            elsif c == '"'
                quote_open = !quote_open
            else
                current += c
            end
        end
        if current.length > 0
            tokens.push(current)
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

    def do()
    end
end

class MessageResponse < Response
    def initialize(args)
        super(args)

        @exp = botbot_expression(args.join)
    end
end

class SendResponse < MessageResponse
    def do(message, room)
        @exp.get.each do |i|
            room.send_message(i)
        end
    end
end

class ReplyResponse < MessageResponse
    def do(message, room)
        @exp.get.each do |i|
            room.send_message(i, message["id"])
        end
    end
end

RESPONSES = {"send" => lambda do |args| return SendResponse.new(args) end,
             "reply" => lambda do |args| return ReplyResponse.new(args) end
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
        respls = []
        @responses.each do |r|
            resp, args = r
            respls.push(RESPONSES[resp].call(args))
        end

        return [@trigger, lambda do |m, r| respls.each do |f| f.do(m, r) end end]
    end
end

class Code
    def initialize(raw)
        @raw = raw

        @triggers = ["msg"]
    end

    def parse()
        blocks = []
        block = Block.new()

        trigger = []
        response = []

        tokens = Tokenizer.new(@raw)
        bit = tokens.next

        while bit
            if @triggers.include?(bit)
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
