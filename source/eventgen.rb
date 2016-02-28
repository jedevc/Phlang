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

class EventQueue < EventGenerator
    def initialize(basegen)
        @base = basegen

        @callbacks = {}
    end

    public
    def onevent(t, &blk)
        if !@callbacks.include? t
            @base.onevent(t) do |*args|
                @callbacks[t].each do |c|
                    if c.call(*args); break; end
                end
            end
            @callbacks[t] = []
        end
        @callbacks[t].push(blk)
    end

    def start()
        super()
        @base.start()
    end

    def stop()
        super()
        @base.stop()
    end

    # Literally everything else
    def method_missing(m, *args, &blk)
        @base.method(m).call(*args, &blk)
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
                EM.run do end
            end
            sleep 1 until EM.reactor_running? # Make sure that EM is running
        end
    end

    private
    # Join reactor thread (must be closed first)
    def stop()
        if @started
            @@count -= 1

            if @@count == 0
                EM.stop_event_loop()
                @@thread.join()
                @@thread = nil
            end
        end

        super()
    end
end
