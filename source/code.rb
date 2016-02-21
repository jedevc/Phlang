require_relative 'expression'

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

        nargs = []
        @args.each do |a|
            resps = TextExpression.new(a, context).calculate
            resps.each do |r|
                nargs.push(r.to_s)
            end
        end
        perform(nargs, packet, room, bot)
    end

    def perform(args, packet, room, bot)
    end

    def lookup(var, *where)
        where.each do |w|
            if w.has_key?(var)
                return w[var]
            end
        end
        return nil
    end
end

class Trigger
    def initialize(args)
        @args = args
    end

    def add(bot, response)
    end
end
