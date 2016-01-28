require_relative 'connection'

# Wraps the connection and provides some helper functions
class Room
    def initialize(room)
        @nick = ""

        @handlers = {}
        onpacket("ping-event", lambda do |packet, _| ping_reply(packet) end)
        onpacket("hello-event", lambda do |packet, _| ready() end)

        @conn = nil
        @first_try = true
        connect(room)
    end

    private
    # Strange function full of dark magic used to connect to euphoria.
    def connect(room)
        @conn = Connection.new(room)

        @conn.receive(lambda do |packet|
            if packet
                if @handlers.has_key?(packet["type"])
                    @handlers[packet["type"]].each do |h|
                        h.call(packet["data"], self)
                    end
                end
            else
                if @first_try
                    @first_try = false
                else
                    sleep(10)
                end
                connect(room)
            end
        end)

        @conn.connect()
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
        if @handlers.has_key?(t)
            @handlers[t].push(f)
        else
            @handlers[t] = [f]
        end
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
end
