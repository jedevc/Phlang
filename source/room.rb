require_relative 'connection'

# Wraps the connection and provides some helper functions
class Room < Connection
    def initialize(room)
        super(room)

        @nick = ""

        onpacket("ping-event", lambda do |packet| ping_reply(packet) end)
        onpacket("hello-event", lambda do |packet| ready() end)
    end

    private
    def ping_reply(packet)
        send(make_packet("ping-reply", {}))
    end

    def ready()
        send_nick(@nick)
    end

    public
    # Identify by a nick in the room
    def send_nick(n)
        @nick = n
        if @connected
            send(make_packet("nick", {"name" => n}))
        end
    end

    # Send a message in the room
    def send_message(content, parent=nil)
        if parent
            send(make_packet("send", {"content" => content, "parent" => parent}))
        else
            send(make_packet("send", {"content" => content}))
        end
    end
end
