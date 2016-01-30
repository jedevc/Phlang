require 'eventmachine'

class EventGenerator
    def initialize()
        @callbacks = {}

        @thread = nil  # Most of the time unused
    end

    protected
    def trigger(type, data=nil)
        if @callbacks.include?(type)
            @callbacks[type].each do |f|
                f.call(data)
            end
        end
    end

    public
    def onevent(type, f)
        if @callbacks.include?(type)
            @callbacks[type].push(f)
        else
            @callbacks[type] = [f]
        end
    end

    def start()
        if !EM.reactor_running?
            @thread = Thread.new do
                EM.run do end
            end
            sleep 1 until EM.reactor_running? # Make sure that EM is running
        end
    end

    def stop()
        if @thread != nil && Thread.current != @thread
            @thread.join()
        end
    end
end
