require_relative 'eventgen'

class Broadcaster < EventGenerator
    @@all = []

    def initialize()
        super()
        @@all.push(self)

        @callbacks = []
    end

    public
    def onevent(&blk)
        @callbacks.push(blk)
    end

    def trigger(message)
        if @started
            @@all.each do |broad|
                broad._trigger(message)
            end
        end
    end

    protected
    def _trigger(message)
        @callbacks.each do |c|
            c.call(message)
        end
    end
end
