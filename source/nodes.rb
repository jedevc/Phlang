class Node
    def perform(context)
    end
end

class RawNode < Node
    def initialize(value)
        @value = value
    end

    def perform(context)
        return @value
    end
end

class VariableNode < Node
    def initialize(name)
        @name = name
    end

    def perform(context)
        return context.variables[@name]
    end
end

class FunctionNode < Node
    def initialize(name, *args)
        @name = name
        @args = args
    end

    def perform(context)
        if context.functions.include? @name
            return context.functions[@name].call(context, *@args.map{|a| a.perform(context)})
        else
            return nil
        end
    end
end

class ApplyNode < Node
    def initialize(*values, &blk)
        @values = values
        @f = blk
    end

    def perform(context)
        return @f.call(context, *@values)
    end
end

class MultiNode < Node
    def initialize(*groups)
        @groups = groups
    end

    def perform(context)
        return @groups.map {|n| n.perform(context)}
    end
end

class RootNode < MultiNode
    def perform(context)
        context.functions["?"] = lambda {|context, args| return args.sample}
        super(context)
    end
end

class TriggerNode < Node
    def initialize(name, exp)
        @name = name
        @trig = Triggers.trigger(@name)

        @expression = exp
        @resps = []
    end

    def attach(resp)
        @resps << resp
    end

    def perform(context)
        context.triggers << lambda do |room, bot|
            @trig.trigger(@expression.perform(context), room) do |trigdata, message|
                trigdata.rmatches.to_a.each_index do |i|
                    context.variables["$#{i}"] = trigdata.rmatches[i]
                end
                context.variables["%time"] = message.time
                context.variables["%ftime"] = Time.at(message.time).utc.strftime("%Y-%m-%d %H:%M:%S")
                context.variables["%sender"] = message.sender
                context.variables["%senderid"] = message.senderid
                context.variables["%room"] = room.name

                @resps.each do |r|
                    break if r.perform(context, message, room, bot)
                end

                trigdata.rmatches.to_a.each_index do |i|
                    context.variables.delete("$#{i}")
                end
                context.variables.reject! {|k| k.start_with? '%'}
            end
        end
    end
end

class ResponseNode < Node
    def initialize(name, exp)
        @name = name
        @resp = Responses.response(@name)

        @expression = exp
    end

    def perform(context, message, room, bot)
        if room.paused
            return true
        else
            return @resp.response(@expression.perform(context), message, room, bot)
        end
    end
end

class SetResponseNode < Node
    def initialize(name, exp)
        @name = name
        @expression = exp
    end

    def perform(context, message, room, bot)
        if room.paused
            return true
        else
            context.variables[@name] = @expression.perform(context)
            return false
        end
    end
end
