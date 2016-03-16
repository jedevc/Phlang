require_relative 'expression'

def lookup(var, *where)
    where.each do |w|
        if w.has_key?(var)
            return w[var]
        end
    end
    return nil
end

def symbol(name)
    case name
    when 'n'
        "\n"
    end
end

class Response
    def initialize(args)
        @extravars = {}
        @funcs = {
            "?" => lambda {|*args| args.sample},
            "%" => lambda {|a| lookup(a, @extravars)},
            "\\" => lambda {|a| nil},
            "$" => lambda {|a| symbol(a)}
        }
        context = ShuntContext.new(@funcs)

        @args = Expression.new(args, context)
    end

    def respond(trigdata, message, room, bot)
        if bot.paused? room
            return false
        else
            @extravars["time"] = message.time
            @extravars["sender"] = message.sender
            @extravars["senderid"] = message.senderid

            # HACK!
            @funcs["%"] = lambda {|a| lookup(a, @extravars, bot.variables(room))}
            @funcs["\\"] = lambda {|a| trigdata[a.to_i]}

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
            "%" => lambda {|a| lookup(a, bot.variables(room))}
        }

        context = ShuntContext.new(@funcs)

        @args = Expression.new(args, context)
    end

    def add(bot, response)
    end

    def trigger(response, message, room, bot)
        nargs = @args.calculate
        nargs.map! {|e| e.to_s}

        perform(response, nargs, message, room, bot)
    end

    def perform(response, args, message, room, bot)
    end
end
