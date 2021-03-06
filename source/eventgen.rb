require 'rubygems'
require 'bundler/setup'

require 'eventmachine'

class EventGenerator
    def initialize()
        @started = false
    end

    public
    def onevent(*args, &blk)
    end

    def start()
        @started = true
    end

    def stop()
        @started = false
    end
end

class EMEventGenerator < EventGenerator
    @@thread = nil
    @@count = 0

    public
    # Start the reactor if not already started
    def start()
        super()

        @@count += 1

        if !EM.reactor_running? and @@thread == nil
            @@thread = Thread.new do
                EM.run
            end

            sleep 1 until EM.reactor_running? # Make sure that EM is running
        end
    end

    # Stop the event generator
    def stop()
        if @started
            @@count -= 1

            if @@count == 0 and Thread.current == Thread.main
                EM.stop_event_loop()
                @@thread.join
                @@thread = nil
            end
        end

        super()
    end

    def self.halt()
        if Thread.current == Thread.main
            EM.stop_event_loop()
            @@thread.join
            @@thread = nil
        end
    end
end
