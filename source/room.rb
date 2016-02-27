require_relative 'connection'
require_relative 'timer'

require_relative 'logservice'

# Wraps the connection and provides some helper functions
class Room
    attr_reader :nick

    def name
        return @conn.roomname
    end

    def exists
        return @conn != nil
    end

    def initialize(room, password=nil)
        @nick = ""

        @conn = nil
        if room_exists?(room)
            @conn = Connection.new(room)
            @conn.onevent("ping-event") do |packet| ping_reply(packet) end
            @conn.onevent("hello-event") do |packet| ready(packet) end
            @conn.start()
        end
        @password = password

        @timer = nil
    end

    private
    # Ping handler
    def ping_reply(packet)
        LogService.get.debug "@#{@nick}: ping reply"
        @conn.send(make_packet("ping-reply", {}))
    end

    # Prepare things for rooms
    def ready(packet)
        if packet["room_is_private"] and @password
            @conn.send(make_packet("auth", {"type" => "passcode", "passcode" => @password}))
        end
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

        @timer.onevent(Time.now + t, &blk)
    end

    # Identify by a nick in the room
    def send_nick(n)
        @nick = n
        @conn.send(make_packet("nick", {"name" => n}))

        LogService.get.debug "@#{@nick}: sending nick"
    end

    # Send a message in the room
    def send_message(content, parent=nil)
        if parent
            @conn.send(make_packet("send", {"content" => content, "parent" => parent}))
            LogService.get.debug "@#{@nick}: sending reply"
        else
            @conn.send(make_packet("send", {"content" => content}))
            LogService.get.debug "@#{@nick}: sending message"
        end
    end

    # Close connections and timers
    def disconnect()
        @conn.stop()
        if @timer
            @timer.stop()
        end
        LogService.get.debug "@#{@nick}: disconnected"
    end
end
