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

class Trigger
    def initialize(args)
        @args = args
    end

    def add(bot, response)
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

    def export(triggers, responses)
        trig = triggers[@trigger[0]].call(@trigger[1])

        resps = []
        @responses.each do |r|
            resp, args = r
            resps.push(responses[resp].call(args))
        end

        return [trig, lambda do |d, m, r, b| resps.each do |f| f.do(d, m, r, b) end end]
    end
end

class CodeParser
    def initialize(raw)
        @raw = raw
    end

    def parse(triggers, responses)
        blocks = []
        block = Block.new()

        trigger = []
        response = []

        tokens = Tokenizer.new(@raw)
        bit = tokens.next

        while bit
            if triggers.include?(bit)
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
            elsif responses.include?(bit)
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
