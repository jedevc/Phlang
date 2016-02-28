require_relative 'connection'
require_relative 'timer'

require_relative 'logservice'

# Wraps the connection and provides some helper functions
class Room
    attr_reader :nick

    attr_accessor :connection
    attr_accessor :timer

    def initialize(room, password=nil)
        @nick = ""

        @connection = nil
        if room_exists?(room)
            @connection = EventQueue.new(Connection.new(room))
            @connection.onevent("ping-event") do |packet| ping_reply(packet) end
            @connection.onevent("hello-event") do |packet| ready(packet) end
            @connection.start()
        end
        @password = password
        @connected = false

        @timer = Timer.new()
        @timer.start()
    end

    def name
        return @connection.roomname
    end

    def exists
        return @connection != nil
    end

    private
    # Ping handler
    def ping_reply(packet)
        LogService.get.debug "@#{@nick}: ping reply"
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
        LogService.get.debug "@#{@nick}: sending nick"
    end

    # Send a message in the room
    def send_message(content, parent=nil)
        if parent
            @connection.send_data(make_packet("send", {"content" => content, "parent" => parent}))
            LogService.get.debug "@#{@nick}: sending reply"
        else
            @connection.send_data(make_packet("send", {"content" => content}))
            LogService.get.debug "@#{@nick}: sending message"
        end
    end

    # Close connections and timers
    def disconnect()
        @connection.stop()
        if @timer
            @timer.stop()
        end
        LogService.get.debug "@#{@nick}: disconnected"
    end
end
