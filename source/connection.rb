require 'websocket-eventmachine-client'
require 'json'

# Create a packet.
def make_packet(name, data)
    return {"type": name, "data": data}
end

# Simple connection to euphoria
class Connection
    attr_reader :roomname
    attr_reader :connected

    def initialize(room, site="euphoria.io")
        @roomname = room
        @connected = false

        @thread = nil
        @mutex = Mutex.new()

        @wsuri = "wss://#{site}/room/#{room}/ws"
        @wscon = nil

        @callbacks = []
    end

    private
    def em_connect()
        EM.run do
            # Attempt to connect
            begin
                @wscon = WebSocket::EventMachine::Client.connect(:uri => @wsuri)
            rescue
                EM.defer do
                    @callbacks.each do |f|
                        f.call(nil)
                    end
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
                        @callbacks.each do |f|
                            f.call(packet)
                        end
                    end
                end

                @wscon.onclose do
                    if @connected
                        EM.defer do
                            @callbacks.each do |f|
                                f.call(nil)
                            end
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
            @mutex.lock()  # Is this needed?
            @wscon.send(data)
            @mutex.unlock()
        end
        return @connected
    end

    # Initialize the connection
    def connect()
        if @wscon == nil
            if EM.reactor_running?
                em_connect()
            else
                @thread = Thread.new do
                    em_connect()
                end
            end
        end
    end

    # Add a callback
    def receive(f)
        @callbacks.push(f)
    end

    # Disconnect from euphoria
    def disconnect()
        @connected = false
        @wscon.close(1000)

        if Thread.current != @thread
            @thread.join()
        end
    end
end
