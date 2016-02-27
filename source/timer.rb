require 'rubygems'
require 'bundler/setup'

require 'eventmachine'

require_relative 'eventgen'

class Timer < EventGenerator
    def initialize()
        super()

        @started = false
    end

    public
    def onevent(type, &blk)
        super(type, &blk)
        start_timer(type, &blk)
    end

    # Start timer groups
    def start()
        super()

        @started = true

        @callbacks.each_key do |k|
            @callbacks[k].each do |f|
                start_timer(k, &blk)
            end
        end
    end

    # Stop timer groups
    def stop()
        @started = false

        super()
    end

    private
    def start_timer(target, &blk)
        length = target - Time.now
        if @started
            EM.add_timer(length) do
                if @started
                    blk.call()
                    @callbacks[target].delete(blk)
                end
            end
        end
    end
end
