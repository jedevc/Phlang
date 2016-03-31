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
                # Create block from previously collected data
                block = Block.new()
                block.add_trigger(trigger[0], trigger.slice(1, trigger.length))
                response.each do |resp|
                    block.add_response(resp[0], resp.slice(1, resp.length))
                end
                blocks.push(block)

                # Reset vars
                trigger = nil
                response = []
            elsif @allowed_triggers.include?(bit)
                # New trigger
                trigger = [bit]
            elsif @allowed_responses.include?(bit)
                # New response
                response.push([bit])
            else
                # Arg for trigger/response
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
