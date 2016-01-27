require 'websocket-eventmachine-client'
require 'json'

# Create a packet.
def make_packet(name, data)
    return {"type": name, "data": data}
end

# Simple connection to euphoria
class Connection
    attr_reader :room
    attr_reader :connected

    def initialize(room, site="euphoria.io")
        @room = room
        @connected = false

        @thread = nil
        @mutex = Mutex.new()

        @wsuri = "wss://#{site}/room/#{room}/ws"
        @wscon = nil

        @callbacks = {}
    end

    protected
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

    public
    # Initialize the connection
    def connect()
        if @wscon == nil
            @thread = Thread.new do
                EM.run do
                    @wscon = WebSocket::EventMachine::Client.connect(:uri => @wsuri)

                    @wscon.onopen do
                        @connected = true
                    end

                    @wscon.onmessage do |data|
                        packet = JSON.load(data)
                        c = @callbacks[packet["type"]]
                        if c
                            c.each do |f|
                                f.call(packet["data"])
                            end
                        end
                    end
                end
            end
        end
    end

    # Add a callback for a packet type
    def onpacket(t, f)
        if @callbacks[t] == nil
            @callbacks[t] = []
        end
        @callbacks[t].push(f)
    end

    # Disconnect - pretty self explanatory
    def disconnect()
        @connected = false
        @wscon.close(1000)

        # No need to join thread, as the process will go on forever.
    end
end
