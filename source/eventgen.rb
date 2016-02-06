require 'eventmachine'

class EventGenerator
    def initialize()
        @callbacks = {}

        @thread = nil  # Most of the time unused
    end

    public
    # Add a callback
    def onevent(type, &blk)
        if @callbacks.include?(type)
            @callbacks[type].push(blk)
        else
            @callbacks[type] = [blk]
        end
    end

    # Start the reactor if not already started
    def start()
        if !EM.reactor_running?
            @thread = Thread.new do
                EM.run do end
            end
            sleep 1 until EM.reactor_running? # Make sure that EM is running
        end
    end

    # Cleanup up various things
    def stop()
    end

    # Kill the event machine and stop everything
    def kill()
        stop()
        EM.stop_event_loop()
        join()
    end

    protected
    # Trigger an event, optionally with some data
    def trigger(type, data=nil)
        if @callbacks.include?(type)
            @callbacks[type].each do |f|
                f.call(data)
            end
        end
    end

    private
    # Join reactor thread (must be closed first)
    def join()
        if @thread != nil && Thread.current != @thread
            @thread.join()
        end
    end
end
