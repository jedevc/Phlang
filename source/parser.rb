require_relative 'factory'
require_relative 'block'

require_relative 'expression'

class Parser
    def initialize(raw, allowed_triggers, allowed_responses)
        @allowed_triggers = allowed_triggers
        @allowed_responses = allowed_responses

        @bits = []
        last = ""
        quotes = false
        raw.each_char do |c|
            if /\s/.match(c)
                if quotes
                    last += c
                else
                    if last.length > 0
                        @bits.push(last)
                        last = ""
                    end
                end
            elsif c == '|'
                quotes = !quotes
                if last.length > 0
                    @bits.push(last)
                    last = ""
                end
            else
                last += c
            end
        end
        if last.length > 0
            @bits.push(last)
        end
    end

    def parse()
        blocks = []
        block = Block.new()

        trigger = []
        response = []

        @bits.each do |bit|
            if @allowed_triggers.include?(bit)
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
            elsif @allowed_responses.include?(bit)
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
