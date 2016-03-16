require_relative 'connection'
require_relative 'timer'
require_relative 'broadcast'

require_relative 'logservice'

# Wraps the connection and provides some helper functions
class Room
    attr_reader :nick

    attr_reader :name
    attr_reader :password

    attr_accessor :connection
    attr_accessor :timer
    attr_accessor :broadcast

    def initialize(room, password=nil)
        @nick = ""

        @connection = nil
        if room_exists?(room)
            @connection = Connection.new(room)
            @connection.onevent("ping-event") do |packet| ping_reply(packet) end
            @connection.onevent("hello-event") do |packet| ready(packet) end
            @connection.start()
        end

        @name = room
        @password = password

        @connected = false

        @timer = Timer.new()
        @timer.start()

        @broadcast = Broadcaster.new()
        @broadcast.start()
    end

    def exists
        return @connection != nil
    end

    private
    # Ping handler
    def ping_reply(packet)
        @connection.send_data(make_packet("ping-reply", {}))
    end

    # Prepare things for rooms
    def ready(packet)
        @connected = true
        if packet["room_is_private"] and @password
            @connection.send_data(make_packet("auth", {"type" => "passcode", "passcode" => @password}))
        end
        send_nick()
    end

    public
    # Identify by a nick in the room
    def send_nick(n=@nick)
        @nick = n
        @connection.send_data(make_packet("nick", {"name" => n}))
    end

    # Send a message in the room
    def send_message(content, parent=nil)
        if parent
            @connection.send_data(make_packet("send", {"content" => content, "parent" => parent}))
        else
            @connection.send_data(make_packet("send", {"content" => content}))
        end
    end

    # Close connections and timers
    def disconnect()
        @connection.stop()
        @timer.stop()
        @broadcast.stop()
    end
end
