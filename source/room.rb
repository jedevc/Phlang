require_relative 'connection'

# Wraps the connection and provides some helper functions
class Room
    def initialize(room)
        @nick = ""

        @conn = nil
        @first_try = true
        connect(room)

        @conn.onevent("ping-event", lambda do |packet| ping_reply(packet) end)
        @conn.onevent("hello-event", lambda do |packet| ready() end)
    end

    private
    # Strange function full of dark magic used to connect to euphoria.
    def connect(room)
        @conn = Connection.new(room)

        @conn.onevent("closed", lambda do |packet|
            if @first_try
                @first_try = false
            else
                sleep(10)
            end
            connect(room)
        end)

        @conn.start()
    end

    # Ping handler
    def ping_reply(packet)
        @conn.send(make_packet("ping-reply", {}))
    end

    # Prepare things for rooms
    def ready()
        send_nick(@nick)
    end

    public
    # Add a handler for a packet type
    def onpacket(t, f)
        @conn.onevent(t, lambda do |packet| f.call(packet, self) end)
    end

    # Identify by a nick in the room
    def send_nick(n)
        @nick = n
        @conn.send(make_packet("nick", {"name" => n}))
    end

    # Send a message in the room
    def send_message(content, parent=nil)
        if parent
            @conn.send(make_packet("send", {"content" => content, "parent" => parent}))
        else
            @conn.send(make_packet("send", {"content" => content}))
        end
    end

    def roomname()
        return @conn.roomname
    end

    def disconnect()
        if @conn
            @conn.stop()
        end
    end
end
