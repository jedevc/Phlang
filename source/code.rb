require_relative 'botbot_responses'

class Response
    def initialize(args)
        @args = []
        args.each do |a|
            @args.push(botbot_response(a))
        end
    end

    def respond(trigdata, packet, room, bot)
        nargs = []
        @args.each do |a|
            resps = a.get
            resps.each do |r|
                na = regexes(trigdata, r)

                more_vars = {}
                if packet.include?("sender")
                    more_vars["sender"] = packet["sender"]["name"]
                end
                more_vars["time"] = Time.now.utc.strftime("%Y-%m-%d %H:%M:%S")
                na = variables(bot.variables(room), na, more_vars)

                nargs.push(na)
            end
        end
        perform(nargs, packet, room, bot)
    end

    def perform(args, packet, room, bot)
    end

    def regexes(rmatch, msg)
        (rmatch.length-1).times do |i|
            msg = msg.gsub(/\\#{i+1}/) {|s| rmatch[i+1]}
        end
        return msg
    end

    def variables(vars, msg, extras={})
        complete = vars.merge(extras)
        complete.each_key do |k|
            msg = msg.gsub(/%#{k}/) {|s| complete[k]}
        end
        return msg
    end
end

class Trigger
    def initialize(args)
        @args = args
    end

    def add(bot, response)
    end
end
