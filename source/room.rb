require_relative 'connection'

require_relative 'timer'

# Wraps the connection and provides some helper functions
class Room
    def initialize(room)
        @nick = ""

        @conn = Connection.new(room)
        @conn.onevent("ping-event") do |packet| ping_reply(packet) end
        @conn.onevent("hello-event") do |packet| ready() end
        @conn.start()

        @timer = nil
    end

    private
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
    def onpacket(t, &blk)
        @conn.onevent(t, &blk)
    end

    # Add a handler to be called in a certain amount of time
    def intime(t, &blk)
        if @timer == nil
            @timer = Timer.new()
            @timer.start()
        end

        @timer.onevent(t, &blk)
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

    # Get the roomname
    def roomname()
        return @conn.roomname
    end

    # Close connections and timers
    def disconnect()
        @conn.stop()
        if @timer
            @timer.stop()
        end
    end
end
