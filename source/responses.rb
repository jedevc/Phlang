require_relative 'logservice'

class Responses
    def self.respond(rtype, data, message, room, bot)
        if bot.paused? room
            return false
        else
            return @@key[rtype].call(data, message, room, bot)
        end
    end

    def self.keys
        return @@key.keys
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

    def self.response_nick(data, message, room, bot)
        if !bot.spam(room)
            room.send_nick(data[-1])
        end
        return false
    end

    @@key = {
        "send" => Responses.method(:response_send),
        "reply" => Responses.method(:response_reply),
        # "broadcast" => Responses.method(:response_broadcast),
        "nick" => Responses.method(:response_nick),
        # "set" => Responses.method(:response_set),
        # "breakif" => Responses.method(:response_breakif)
    }
end

# class BroadcastResponse < Response
#     def perform(args, message, room, bot)
#         args.each do |a|
#             room.broadcast.trigger(a)
#         end
#         return false
#     end
# end
#
# class NickResponse < Response
#     def perform(args, message, room, bot)
#         bot.spam(room)
#         room.send_nick(args[-1])
#         return false
#     end
# end
#
# class SetResponse < Response
#     def perform(args, message, room, bot)
#         if args.length == 2
#             var = args[0]
#             val = args[1]
#             bot.variables(room)[var] = val
#         end
#         return false
#     end
# end
#
# class BreakResponse < Response
#     def perform(args, message, room, bot)
#         if args.length == 2
#             first = args[0]
#             second = args[1]
#
#             return first == second
#         end
#         return false
#     end
# end
#
# class CreateResponse < Response
#     def perform(args, message, room, bot)
#         if args.length >= 2
#             nick = args[0]
#             code = args.slice(1, args.length).join(" ")
#
#             conf = HIGH_SECURITY
#             nb = PhlangBot.new(nick, code, conf, message.sender)
#             r = Room.new(room.name, room.password)
#             nb.add_room(r)
#             bot.group.add(nb)
#         end
#         return false
#     end
# end
#
# class LogResponse < Response
#     def perform(args, message, room, bot)
#         message = args.join("")
#         LogService.info "@#{room.nick} logged: #{message}"
#         return false
#     end
# end
#
# class ListResponse < Response
#     def perform(args, message, room, bot)
#         msg = ""
#         bot.group.each do |b|
#             name = b.basename
#             rooms = b.room_names.map {|r| "&#{r}"}
#             msg += "@#{name} in [#{rooms.join(", ")}]\n"
#         end
#         room.send_message(msg, message.id)
#         return false
#     end
# end
#
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
