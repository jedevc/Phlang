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

    def respond(trigdata, packet, room, bot)
        extravars = {"time" => Time.now.utc.strftime("%Y-%m-%d %H:%M:%S")}
        if packet.has_key?("sender")
            extravars["sender"] = packet["sender"]["name"]
        end
        funcs = {
            "\\" => lambda {|a| trigdata[a.to_i]},
            "%" => lambda {|a| lookup(a, bot.variables(room), extravars)}
        }
        context = ShuntContext.new(funcs)

        nargs = Expression.new(@args, context).calculate
        nargs.map! {|e| e.to_s}

        perform(nargs, packet, room, bot)
    end

    def perform(args, packet, room, bot)
    end
end

class Trigger
    def initialize(args)
        @args = args
    end

    def add(bot, response)
    end

    def trigger(response, packet, room, bot)
        funcs = {
            "%" => lambda {|a| lookup(a, bot.variables(room))}
        }
        context = ShuntContext.new(funcs)

        nargs = Expression.new(@args, context).calculate
        nargs.map! {|e| e.to_s}

        return perform(response, nargs, packet, room, bot)
    end

    def perform(response, args, packet, room, bot)
    end
end
