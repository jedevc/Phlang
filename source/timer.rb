require 'eventmachine'

require_relative 'eventgen'

class Timer < EventGenerator
    def initialize()
        super()

        @started = false
    end

    public
    def onevent(type, f)
        super(type, f)

        if @started
            EM.add_timer(type) do
                f.call()
                @callbacks[type].delete(f)
            end
        end
    end

    def start()
        super()

        @started = true

        @callbacks.each_key do |k|
            @callbacks[k].each do |f|
                EM.add_timer(k) do
                    f.call();
                    @callbacks[k].delete(f)
                end
            end
        end
    end

    def stop()
        @started = false

        super()
    end
end
