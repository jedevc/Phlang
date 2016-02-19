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
class Connection < EventGenerator
    attr_reader :roomname
    attr_reader :status

    def initialize(room)
        super()

        @roomname = room
        @status = :closed

        @mutex = Mutex.new()

        @wsuri = "wss://#{SITE_IP}/room/#{room}/ws"
        @wscon = nil
    end

    public
    # Send a Ruby hash through the connection formatted as JSON.
    def send(packet)
        if @status == :open
            data = JSON.dump(packet)
            @mutex.lock()
            @wscon.send(data)
            @mutex.unlock()
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
        @wscon.close(1000)

        super()
    end

    private
    # Low level connect to euphoria and manage disconnects
    def em_connect()
        @wscon = WebSocket::EventMachine::Client.connect(:uri => @wsuri)
        @wscon.comm_inactivity_timeout = 60

        @wscon.onopen do
            @status = :open
        end

        @wscon.onmessage do |data|
            EM.defer do
                packet = JSON.load(data)
                if @status == :open
                    trigger(packet["type"], packet["data"])
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
