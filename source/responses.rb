require_relative 'code'

module RegexBackreference
    def backrefs(rmatch, msg)
        (rmatch.length-1).times do |i|
            msg = msg.gsub("\\#{i+1}", rmatch[i+1])
        end
        return msg
    end
end

class BotbotResponse < Response
    def initialize(args)
        super(args)
        @exp = botbot_expression(@args.join(" "))
    end
end

class SendResponse < BotbotResponse
    include RegexBackreference

    def do(trigdata, message, room, bot)
        @exp.get.each do |msg|
            if msg.length > 0
                room.send_message(backrefs(trigdata, msg))
            end
        end
    end
end

class ReplyResponse < BotbotResponse
    include RegexBackreference

    def do(trigdata, message, room, bot)
        @exp.get.each do |msg|
            if msg.length > 0
                room.send_message(backrefs(trigdata, msg), message["id"])
            end
        end
    end
end

class NickResponse < BotbotResponse
    include RegexBackreference

    def do(trigdata, message, room, bot)
        nick = @exp.get[0]
        room.send_nick(backrefs(trigdata, nick))
    end
end

class CreateResponse < Response
    include RegexBackreference

    def do(trigdata, message, room, bot)
        nick = backrefs(trigdata, @args[0])
        code = backrefs(trigdata, @args.slice(1, @args.length).join(" "))
        nb = PhlangBot.new(nick, code, ADMIN_CONFIG, message["sender"]["name"])
        r = Room.new(room.name)
        nb.add_room(r)
        bot.group.add(nb)
    end
end

RESPONSES = {"send" => lambda do |args| return SendResponse.new(args) end,
             "reply" => lambda do |args| return ReplyResponse.new(args) end,
             "nick" => lambda do |args| return NickResponse.new(args) end,
             "create" => lambda do |args| return CreateResponse.new(args) end
}
