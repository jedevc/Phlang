require_relative 'code'
require_relative 'config'

require_relative 'logservice'

class SendResponse < Response
    def perform(args, packet, room, bot)
        args.each do |a|
            room.send_message(a)
        end
        return false
    end
end

class ReplyResponse < Response
    def perform(args, packet, room, bot)
        args.each do |a|
            room.send_message(a, packet["id"])
        end
        return false
    end
end

class NickResponse < Response
    def perform(args, packet, room, bot)
        room.send_nick(args[-1])
        return false
    end
end

class SetResponse < Response
    def perform(args, packet, room, bot)
        if args.length == 2
            var = args[0]
            val = args[1]
            bot.variables(room)[var] = val
        end
        return false
    end
end

class BreakResponse < Response
    def perform(args, packet, room, bot)
        if args.length == 2
            first = args[0]
            second = args[1]

            return first == second
        end
        return false
    end
end

class CreateResponse < Response
    def perform(args, packet, room, bot)
        if args.length >= 2
            nick = args[0]
            code = args.slice(1, args.length).join(" ")
            bot.fork_new_bot(nick, code, room.name, packet["sender"]["name"])
        end
        return false
    end
end

class LogResponse < Response
    def perform(args, packet, room, bot)
        message = args.join(" ")
        LogService.get.info "@#{room.nick} logged: #{message}"
        return false
    end
end
