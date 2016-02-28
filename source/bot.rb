# A bot responds to low-level triggers from a collection of rooms
class Bot
    attr_reader :basename

    attr_accessor :group

    def initialize(name)
        @group = nil

        @basename = name
        @rooms = []

        @handles = {}
    end

    public
    # Add a room to the collection for monitoring
    def add_room(room)
        if not room.exists
            return false
        end

        # Add handlers to room
        @handles.each_key do |type|
            @handles[type].each do |h|
                room.connection.onevent(type) do |packet|
                    h.call(packet, room)
                end
            end
        end

        room.send_nick(@basename)
        @rooms.push(room)

        return true
    end

    # Remove a room from monitoring
    def remove_room(room)
        room.disconnect()
        @rooms.delete(room)
    end

    # Remove all the rooms from monitoring
    def remove_all_rooms()
        @rooms.each do |room|
            room.disconnect()
        end
        @rooms = []
    end

    # Get the rooms that a bot is part of
    def room_names()
        return @rooms.map {|r| r.name}
    end

    # Add a handler for a certain event type
    def add_handle(type, &blk)
        if @handles.has_key? type
            @handles[type].push(blk)
        else
            @handles[type] = [blk]
        end

        @rooms.each do |r|
            r.connection.onevent(type) do |packet|
                blk.call(packet, r)
            end
        end
    end
end
