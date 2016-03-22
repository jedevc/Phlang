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
        @extravars = {}
        @funcs = {
            "?" => lambda {|*args| args.sample},
            "%" => lambda {|a| lookup(a, @extravars)},
            "$" => lambda {|a| nil}
        }
        context = ShuntContext.new(@funcs)

        @args = Expression.new(args, context)
    end

    def respond(trigdata, message, room, bot)
        if bot.paused? room
            return false
        else
            @extravars["time"] = message.time
            @extravars["ftime"] = Time.at(message.time).utc.strftime("%Y-%m-%d %H:%M:%S")
            @extravars["sender"] = message.sender
            @extravars["senderid"] = message.senderid

            # HACK!
            @funcs["%"] = lambda {|a| lookup(a, @extravars, bot.variables(room))}
            @funcs["$"] = lambda {|a| trigdata[a.to_i]}

            nargs = @args.calculate
            nargs.map! {|e| e.to_s}
            return perform(nargs, message, room, bot)
        end
    end

    def perform(args, message, room, bot)
    end
end

class Trigger
    def initialize(args)
        @funcs = {
            "%" => lambda {|a| nil}
        }

        context = ShuntContext.new(@funcs)

        @args = Expression.new(args, context)
    end

    def add(bot, response)
    end

    def trigger(response, message, room, bot)
        @funcs["%"] = lambda {|a| lookup(a, bot.variables(room))}

        nargs = @args.calculate
        nargs.map! {|e| e.to_s}

        perform(response, nargs, message, room, bot)
    end

    def perform(response, args, message, room, bot)
    end
end
