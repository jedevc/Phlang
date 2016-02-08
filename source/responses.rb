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
                room.send_message(regexes(trigdata, msg))
            end
        end
    end
end

class ReplyResponse < BotbotResponse
    def do(trigdata, message, room, bot)
        @exp.get.each do |msg|
            if msg.length > 0
                room.send_message(regexes(trigdata, msg), message["id"])
            end
        end
    end
end

class NickResponse < BotbotResponse
    def do(trigdata, message, room, bot)
        nick = @exp.get[0]
        room.send_nick(regexes(trigdata, nick))
    end
end

class CreateResponse < Response
    def do(trigdata, message, room, bot)
        if @args.length >= 2
            nick = regexes(trigdata, @args[0])
            code = regexes(trigdata, @args.slice(1, @args.length).join(" "))
            bot.fork_new_bot(nick, code, room.name, message["sender"]["name"])
        end
    end
end

class LogResponse < Response
    def do(trigdata, message, room, bot)
        message = regexes(trigdata, @args.join(" "))
        LogService.get.info "@#{room.nick} logged: #{message}"
    end
end
