require_relative 'room'

class PhlangRoom < Room
    attr_accessor :paused
    attr_accessor :responded

    def initialize(room, password=nil, spamlimit=nil)
        super(room, password)

        @paused = false
        @responded = false

        @spamlimit = spamlimit
        @spam = 0
        @spamdelay = 10
        @lastcheck = Time.now
    end

    public
    def spam(amount=1)
        @responded = true
        if !@spamlimit.nil?
            if Time.now > @lastcheck + @spamdelay
                @spam = 0
                @lastcheck = Time.now
            end

            @spam += amount
            if @spam > @spamlimit * @spamdelay
                send_message("/me has been paused (possible spam attack).")
                @spam = 0
                @paused = true
            end
        end
        return @paused
    end
end
