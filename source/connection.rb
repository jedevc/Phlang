require 'websocket-eventmachine-client'
require 'json'

require_relative 'eventgen'

# Create a packet.
def make_packet(name, data)
    return {"type": name, "data": data}
end

# Simple connection to euphoria
class Connection < EventGenerator
    attr_reader :roomname
    attr_reader :connected

    def initialize(room, site="euphoria.io")
        super()

        @roomname = room
        @connected = false

        @mutex = Mutex.new()

        @wsuri = "wss://#{site}/room/#{room}/ws"
        @wscon = nil
    end

    private
    def em_connect()
        EM.run do
            # Attempt to connect
            begin
                @wscon = WebSocket::EventMachine::Client.connect(:uri => @wsuri)
            rescue
                EM.defer do
                    trigger("closed")
                end
            end

            if @wscon
                @wscon.comm_inactivity_timeout = 60

                @wscon.onopen do
                    @connected = true
                end

                @wscon.onmessage do |data|
                    EM.defer do
                        packet = JSON.load(data)
                        trigger(packet["type"], packet["data"])
                    end
                end

                @wscon.onclose do
                    if @connected
                        EM.defer do
                            trigger("closed")
                        end
                    end
                end
            end
        end
    end

    public
    # Send a Ruby hash through the connection formatted as JSON.
    def send(packet)
        if @connected
            data = JSON.dump(packet)
            @mutex.lock()
            @wscon.send(data)
            @mutex.unlock()
        end
        return @connected
    end

    # Initialize the connection
    def start()
        super()

        if @wscon == nil
            em_connect()
        end
    end

    # Disconnect from euphoria
    def stop()
        @connected = false
        @wscon.close(1000)

        super()
    end
end
