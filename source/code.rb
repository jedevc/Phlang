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

class SendResponse < Response
    def do(message, room)
        room.send_message(@args.join)
    end
end

class ReplyResponse < Response
    def do(message, room)
        room.send_message(@args.join, message["id"])
    end
end

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
            if resp == "send"
                respls.push(SendResponse.new(args))
            elsif resp == "reply"
                respls.push(ReplyResponse.new(args))
            end
        end

        return [@trigger, lambda do |m, r| respls.each do |f| f.do(m, r) end end]
    end
end

class Code
    def initialize(raw)
        @raw = raw

        @responses = ["send", "reply"]
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
                # puts("Trigger: " + bit)

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
            elsif @responses.include?(bit)
                # puts("Response: " + bit)
                if response.length > 0
                    block.add_response(response[0], response.slice(1, response.length))
                    response = []
                end
                response.push(bit)
            else
                # puts("Arg: " + bit)
                if response.length > 0
                    response.push(bit)
                elsif trigger.length > 0
                    trigger.push(bit)
                end
            end

            bit = tokens.next
        end

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
