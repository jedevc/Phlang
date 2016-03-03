require_relative 'expression'

def lookup(var, *where)
    where.each do |w|
        if w.has_key?(var)
            return w[var]
        end
    end
    return nil
end

class Response
    def initialize(args)
        @args = args
    end

    def respond(trigdata, message, room, bot)
        extravars = {
            "time" => message.time,
            "sender" => message.sender
        }

        funcs = {
            "\\" => lambda {|a| trigdata[a.to_i]},
            "%" => lambda {|a| lookup(a, bot.variables(room), extravars)},
            "?" => lambda {|*args| args.sample}
        }
        context = ShuntContext.new(funcs)

        nargs = Expression.new(@args, context).calculate
        nargs.map! {|e| e.to_s}

        perform(nargs, message, room, bot)
    end

    def perform(args, message, room, bot)
    end
end

class Trigger
    def initialize(args)
        @args = args
    end

    def add(bot, response)
    end

    def trigger(response, message, room, bot)
        funcs = {
            "%" => lambda {|a| lookup(a, bot.variables(room))}
        }
        context = ShuntContext.new(funcs)

        nargs = Expression.new(@args, context).calculate
        nargs.map! {|e| e.to_s}

        return perform(response, nargs, message, room, bot)
    end

    def perform(response, args, message, room, bot)
    end
end
