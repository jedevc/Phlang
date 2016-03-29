require_relative 'factory'
require_relative 'block'

require_relative 'expression'

class Parser
    def initialize(raw, allowed_triggers, allowed_responses)
        @allowed_triggers = allowed_triggers
        @allowed_responses = allowed_responses

        @bits = Tokens(raw)
    end

    def parse()
        blocks = []

        trigger = nil
        response = []

        @bits.each do |bit|
            if bit == "end"
                block = Block.new()
                block.add_trigger(trigger[0], trigger.slice(1, trigger.length))
                response.each do |resp|
                    block.add_response(resp[0], resp.slice(1, resp.length))
                end

                blocks.push(block)

                trigger = nil
                response = []
            elsif @allowed_triggers.include?(bit)
                trigger = [bit]
            elsif @allowed_responses.include?(bit)
                response.push([bit])
            else
                if response.length > 0
                    response[-1].push(bit)
                elsif trigger.length > 0
                    trigger.push(bit)
                end
            end
        end

        return blocks
    end
end
