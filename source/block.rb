require_relative 'factory'

class Block
    def initialize()
        @trigger = nil
        @responses = []
    end

    public
    def add_trigger(trigger)
        @trigger = [trigger]
    end

    def add_response(response)
        @responses.push([response])
    end

    def add_args(*args)
        if @responses.length > 0
            @responses[-1].push(*args)
        else
            @trigger.push(*args)
        end
    end

    def export(allowed_triggers, allowed_responses)
        if @trigger and allowed_triggers.include?(@trigger[0]) and @responses.length > 0
            trig = TriggerFactory.build(@trigger[0], @trigger[1])

            resps = []
            @responses.each do |r|
                resp, args = r
                if allowed_responses.include?(resp)
                    resps.push(ResponseFactory.build(resp, args))
                end
            end

            return [trig, lambda do |d, m, r, b|
                resps.each do |f|
                    return if f.respond(d, m, r, b)
                end
            end]
        else
            return nil
        end
    end
end
