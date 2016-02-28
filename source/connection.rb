require 'rubygems'
require 'bundler/setup'

require 'websocket-eventmachine-client'
require 'json'
require 'open-uri'

require_relative 'eventgen'

# The raw ip for euphoria.io
SITE_NAME = "euphoria.io"
SITE_IP = "54.148.52.205"

# Create a packet.
def make_packet(name, data)
    return {"type" => name, "data" => data}
end

# Test if a room exists
def room_exists?(room)
    begin
        open("https://#{SITE_NAME}/room/#{room}")
        return true
    rescue OpenURI::HTTPError
        return false
    end
end

# Simple connection to euphoria
class Connection < EMEventGenerator
    attr_reader :roomname
    attr_reader :status

    def initialize(room)
        super()

        @callbacks = {}

        @roomname = room
        @status = :closed

        @mutex = Mutex.new()

        @wsuri = "wss://#{SITE_IP}/room/#{room}/ws"
        @wscon = nil
    end

    public
    def onevent(ptype, &blk)
        if @callbacks.has_key? ptype
            @callbacks[ptype].push(blk)
        else
            @callbacks[ptype] = [blk]
        end
    end

    # Send a Ruby hash through the connection formatted as JSON.
    def send_data(packet)
        if @status == :open
            data = JSON.dump(packet)
            @mutex.synchronize do
                @wscon.send(data)
            end
            return true
        end
        return false
    end

    # Initialize the connection
    def start()
        super()

        if @wscon == nil
            @status = :opening
            em_connect()
        end
    end

    # Disconnect from euphoria
    def stop()
        @status = :closing
        @mutex.synchronize do
            @wscon.close(1000)
        end

        super()
    end

    private
    # Low level connect to euphoria and manage disconnects
    def em_connect()
        @mutex.synchronize do
            @wscon = WebSocket::EventMachine::Client.connect(:uri => @wsuri)
        end
        @wscon.comm_inactivity_timeout = 60

        @wscon.onopen do
            @status = :open
        end

        @wscon.onmessage do |data|
            EM.defer do
                packet = JSON.load(data)
                if @status == :open
                    if @callbacks.has_key? packet["type"]
                        @callbacks[packet["type"]].each do |c|
                            c.call(packet["data"])
                        end
                    end
                end
            end
        end

        @wscon.onclose do |code, reason|
            if @status == :closing
                @status = :closed
            elsif @status == :open || @status == :opening
                @status = :opening
                EM.add_timer(10) do
                    em_connect()
                end
            end
        end
    end
end
