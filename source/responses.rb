require_relative 'code'
require_relative 'config'

require_relative 'logservice'

class BotbotResponse < Response
    def initialize(args)
        super(args)
        @exp = botbot_expression(@args.join(" "))
    end
end

class SendResponse < BotbotResponse
    def do(trigdata, message, room, bot)
        @exp.get.each do |msg|
            if msg.length > 0
                tosend = regexes(trigdata, msg)
                tosend = variables(bot.variables(room), tosend)
                room.send_message(tosend)
            end
        end
        return false
    end
end

class ReplyResponse < BotbotResponse
    def do(trigdata, message, room, bot)
        @exp.get.each do |msg|
            if msg.length > 0
                tosend = regexes(trigdata, msg)
                tosend = variables(bot.variables(room), tosend)
                room.send_message(tosend, message["id"])
            end
        end
        return false
    end
end

class NickResponse < BotbotResponse
    def do(trigdata, message, room, bot)
        nick = regexes(trigdata, @exp.get[0])
        nick = variables(bot.variables(room), nick)
        room.send_nick(nick)
        return false
    end
end

class SetResponse < Response
    def do(trigdata, message, room, bot)
        if @args.length >= 2 and @args[0][0] == '%'
            var = regexes(trigdata, @args[0].slice(1, @args[0].length))
            var = variables(bot.variables(room), var)

            val = regexes(trigdata, @args.slice(1, @args.length).join(" "))
            val = variables(bot.variables(room), val)

            bot.variables(room)[var] = val
        end
        return false
    end
end

class BreakResponse < Response
    def do(trigdata, message, room, bot)
        if @args.length >= 2 and @args[0][0] == '%'
            first = regexes(trigdata, @args[0])
            first = variables(bot.variables(room), first)

            second = regexes(trigdata, @args.slice(1, @args.length).join(" "))
            second = variables(bot.variables(room), second)

            puts("#{first}, #{second}")
            return first == second
        end
        return false
    end
end

class CreateResponse < Response
    def do(trigdata, message, room, bot)
        if @args.length >= 2
            nick = regexes(trigdata, @args[0])
            nick = variables(bot.variables(room), nick)
            code = regexes(trigdata, @args.slice(1, @args.length).join(" "))
            code = variables(bot.variables(room), code)
            bot.fork_new_bot(nick, code, room.name, message["sender"]["name"])
        end
        return false
    end
end

class LogResponse < Response
    def do(trigdata, message, room, bot)
        message = regexes(trigdata, @args.join(" "))
        message = variables(bot.variables(room), message)
        LogService.get.info "@#{room.nick} logged: #{message}"
        return false
    end
end
