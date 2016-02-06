require_relative 'bot'
require_relative 'room'
require_relative 'phlangbot'

class MetaBot < Bot
    def initialize()
        super("PhlangBot")

        add_handle("send-event") do |message, room|
            parts = /^!(\S*)(?: ([\s\S]*))?$/.match(message["content"])
            if parts
                cmd = parts[1]
                args = parts[2]

                if cmd == "help" and args == "@#{room.nick}"
                    room.send_message(":warning: This bot is still under dev.", message["id"])
                    next true
                elsif cmd == "ping" and (args == nil or args == "@#{room.nick}")
                    room.send_message("Pong!", message["id"])
                    next true
                elsif cmd == "phlang"
                    nac = /@(\S*) ([\s\S]*)/.match(args)
                    next false if nac == nil
                    b = PhlangBot.new(nac[1], nac[2], ADMIN_CONFIG, message["sender"]["name"])
                    r = Room.new(room.name)
                    b.add_room(r)

                    @group.add(b)
                    next true
                end
            end
        end
    end
end
