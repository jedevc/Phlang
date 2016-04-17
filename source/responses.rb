require_relative 'logservice'

require_relative 'phlangbot'
require_relative 'room'

class Responses
    def self.respond(rtype, data, message, room, bot)
        if bot.paused? room
            return false
        else
            return @@merged[rtype].call(data, message, room, bot)
        end
    end

    def self.simple
        return @@simple.keys
    end
    def self.advanced
        return @@advanced.keys
    end

    private
    def self.response_send(data, message, room, bot)
        data.each do |d|
            if !bot.spam(room)
                room.send_message(d)
            end
        end
        return false
    end

    def self.response_reply(data, message, room, bot)
        data.each do |d|
            if !bot.spam(room)
                room.send_message(d, message.id)
            end
        end
        return false
    end

    def self.response_broadcast(data, message, room, bot)
        data.each do |d|
            room.broadcast.trigger(d)
        end
        return false
    end

    def self.response_nick(data, message, room, bot)
        if !bot.spam(room)
            room.send_nick(data[-1])
        end
        return false
    end

    def self.response_breakif(data, message, room, bot)
        return data.length == 2 && data[0].to_s == data[1].to_s
    end

    @@simple = {
        "send" => Responses.method(:response_send),
        "reply" => Responses.method(:response_reply),
        "broadcast" => Responses.method(:response_broadcast),
        "nick" => Responses.method(:response_nick),
        "breakif" => Responses.method(:response_breakif)
    }

    def self.response_create(data, message, room, bot)
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

    def self.response_log(data, message, room, bot)
        LogService.info "@#{room.nick} logged: #{data.join}"
        return false
    end

    def self.response_list(data, message, room, bot)
        msg = ""
        bot.group.each do |b|
            name = b.basename
            rooms = b.room_names.map {|r| "&#{r}"}
            msg += "@#{name} in [#{rooms.join(", ")}]\n"
        end
        room.send_message(msg, message.id)
        return false
    end

    @@advanced = {
        "log" => Responses.method(:response_log),
        "create" => Responses.method(:response_create),
        "list" => Responses.method(:response_list)
    }

    @@merged = @@simple.merge(@@advanced)
end

# class SaveResponse < Response
#     def perform(args, message, room, bot)
#         if args.length > 0
#             bot.group.save(args[0])
#         end
#         return false
#     end
# end
#
# class RecoverResponse < Response
#     def perform(args, message, room, bot)
#         if args.length > 0
#             bot.group.recover(args[0])
#         else
#             bot.group.recover()
#         end
#
#         return false
#     end
# end
