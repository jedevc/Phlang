require_relative 'bot'
require_relative 'room'
require_relative 'phlangbot'
require_relative 'phlangbotgroup'

class MetaBot < Bot
    def initialize()
        super("PhlangBot")

        @bots = PhlangBotGroup.new()
        add_handle("send-event") do |message, room|
            parts = /^!(\S*)(?: ([\s\S]*))?$/.match(message["content"])
            if parts
                cmd = parts[1]
                args = parts[2]

                if cmd == "help" and args == "@#{@name}"
                    room.send_message(":warning: This bot is still under dev.", message["id"])
                    return true
                elsif cmd == "ping"
                    room.send_message("Pong!", message["id"])
                    return true
                elsif cmd == "version"
                    room.send_message("Currently running phlang version 'dev'.", message["id"])
                    return true
                elsif cmd == "phlang"
                    nac = /@(\S*) ([\s\S]*)/.match(args)
                    return false if nac == nil
                    b = PhlangBot.new(nac[1], nac[2], ADMIN_CONFIG, message["sender"]["name"])
                    r = Room.new(room.roomname)
                    b.add_room(r)

                    @bots.add(b)
                    next true
                end
            end
        end
    end
end
