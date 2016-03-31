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
        responses = []

        @bits.each do |bit|
            if bit == "end"
                # Create block from previously collected data
                if !trigger.nil? and responses.length > 0
                    block = Block.new()
                    block.add_trigger(trigger[0], trigger.slice(1, trigger.length))
                    responses.each do |resp|
                        block.add_response(resp[0], resp.slice(1, resp.length))
                    end
                    blocks.push(block)
                end

                # Reset vars
                trigger = nil
                responses = []
            elsif @allowed_triggers.include?(bit)
                # New trigger
                trigger = [bit]
            elsif @allowed_responses.include?(bit)
                # New response
                responses.push([bit])
            else
                # Arg for trigger/response
                if responses.length > 0
                    responses[-1].push(bit)
                elsif trigger.length > 0
                    trigger.push(bit)
                end
            end
        end

        return blocks
    end
end
