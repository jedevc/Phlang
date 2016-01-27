require_relative 'bot'
require_relative 'builtin'

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

class Trigger
    def initialize(trig, trig_args, resp, resp_args)
        @trig = trig
        @trig_args = trig_args
        @resp = resp
        @resp_args = botbot_expression(resp_args)
    end

    def attempt(message, room)
        if @trig.call(@trig_args, message, room)
            @resp.call(@resp_args, message, room)
            return true
        else
            return false
        end
    end
end

class Code
    def initialize(raw)
        @raw = raw

        @responses = {"send" => lambda do |args, message, room|
            args.get.each do |a|
                room.send_message(a)
            end
        end,
        "reply" => lambda do |args, message, room|
            args.get.each do |a|
                room.send_message(a, message["id"])
            end
        end}

        @triggers = {"msg" => lambda do |args, message, room|
            return Regexp.new(args).match(message["content"])
        end}
    end

    def parse()
        tokens = Tokenizer.new(@raw)
        bit = tokens.next

        final = []

        trigger = nil
        response = nil
        targs = ""
        rargs = ""
        while bit
            if @triggers.has_key?(bit)
                if trigger
                    final.push(Trigger.new(trigger, targs, response, rargs))
                    response = nil
                    targs = ""
                end
                trigger = @triggers[bit]
            elsif @responses.has_key?(bit)
                rargs = ""
                response = @responses[bit]
            else
                if response
                    rargs += bit
                elsif trigger
                    targs += bit
                end
            end
            bit = tokens.next
        end

        if trigger
            final.push(Trigger.new(trigger, targs, response, rargs))
        end

        return final
    end
end
