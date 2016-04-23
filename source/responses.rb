require_relative 'logservice'

require_relative 'phlangbot'
require_relative 'room'

class Response
    def response(data, message, room, bot)
    end
end

class SendResponse < Response
    def response(data, message, room, bot)
        data.each do |d|
            break if bot.spam(room)
            room.send_message(d)
        end
        return false
    end
end

class ReplyResponse < Response
    def response(data, message, room, bot)
        data.each do |d|
            break if bot.spam(room)
            room.send_message(d, message.id)
        end
        return false
    end
end

class BroadcastResponse < Response
    def response(data, message, room, bot)
        data.each do |d|
            room.broadcast.trigger(d)
        end
        return false
    end
end

class NickResponse < Response
    def response(data, message, room, bot)
        if !bot.spam(room)
            room.send_nick(data[-1])
        end
        return false
    end
end

class BreakifResponse < Response
    def response(data, message, room, bot)
        return data.length == 2 && data[0].to_s == data[1].to_s
    end
end

class CreateResponse < Response
    def response(data, message, room, bot)
        if data.length >= 2
            nick = data[0]
            code = data.slice(1, data.length).join

            conf = HIGH_SECURITY
            nb = PhlangBot.new(nick, code, conf, message.sender)
            r = Room.new(room.name, room.password)
            nb.add_room(r)
            bot.group.add(nb)
        end
        return false
    end
end

class LogResponse < Response
    def response(data, message, room, bot)
        LogService.info "@#{room.nick} logged: #{data.join}"
        return false
    end
end

class ListResponse < Response
    def response(data, message, room, bot)
        msg = ""
        bot.group.each do |b|
            name = b.basename
            rooms = b.room_names.map {|r| "&#{r}"}
            msg += "@#{name} in [#{rooms.join(", ")}]\n"
        end
        room.send_message(msg, message.id)
        return false
    end
end

class SaveResponse < Response
    def response(data, message, room, bot)
        if data.length > 0
            bot.group.save(data.join)
        end
        return false
    end
end

class RecoverResponse < Response
    def response(data, message, room, bot)
        if data.length == 0
            bot.group.recover()
        else
            bot.group.recover(data.join)
        end

        return false
    end
end

class Responses
    def self.response(rtype)
        return @@merged[rtype].call
    end

    def self.simple
        return @@simple.keys
    end
    def self.advanced
        return @@advanced.keys
    end

    @@simple = {
        "send" => SendResponse.method(:new),
        "reply" => ReplyResponse.method(:new),
        "broadcast" => BroadcastResponse.method(:new),
        "nick" => NickResponse.method(:new),
        "breakif" => BreakifResponse.method(:new)
    }

    @@advanced = {
        "log" => LogResponse.method(:new),
        "create" => CreateResponse.method(:new),
        "list" => ListResponse.method(:new),
        "save" => SaveResponse.method(:new),
        "recover" => RecoverResponse.method(:new)
    }

    @@merged = @@simple.merge(@@advanced)
end
