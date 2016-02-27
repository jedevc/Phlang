require 'rubygems'
require 'bundler/setup'

require 'eventmachine'

require_relative 'eventgen'

class Timer < EMEventGenerator
    def initialize()
        @unstarted = []
    end

    public
    def onevent(type, &blk)
        start_timer(type, &blk)
    end

    # Start timer groups
    def start()
        super()

        @unstarted.each do |unst|
            endtime, func = unst
            start_timer(endtime, &func)
        end
    end

    private
    def start_timer(target, &blk)
        length = target - Time.now
        if @started
            EM.add_timer(length) do
                if @started
                    blk.call()
                end
            end
        else
            @unstarted.push([target, blk])
        end
    end
end
