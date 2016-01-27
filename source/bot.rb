# A bot responds to low-level triggers from a collection of rooms
class Bot
    attr_reader :name

    def initialize(name)
        @name = name
        @rooms = []

        @handles = {}
    end

    public
    # Add a room to the collection for monitoring
    def add_room(room)
        if !room.connected
            room.connect()
        end

        # Add handlers to room
        @handles.each_key do |type|
            room.onpacket(type, lambda do |packet|
                @handles[type].each do |h|
                    if h.call(packet, room); break; end
                end
            end)
        end

        room.send_nick(@name)
        @rooms.push(room)
    end

    # Remove a room from monitoring
    def remove_room(room)
        if room.connected
            room.disconnect()
        end
        @rooms.delete(room)
    end

    # Remove all the rooms from monitoring
    def remove_all_rooms()
        @rooms.each do |r|
            if r.connected
                r.disconnect()
            end
        end
        @rooms = []
    end

    # Get the number of rooms that a bot is part of
    def room_count()
        return @rooms.length
    end

    # Manually launch a trigger - useful for custom triggers and stuff
    def trigger(type)
        if @handles[type] != nil
            @handles[type].each do |h|
                h.call()
            end
        end
    end

    # Add a handler for a certain event type
    def add_handle(type, f)
        # Create the handler if it doesn't already exist
        if @handles[type] == nil
            @handles[type] = []
            @rooms.each do |r|
                r.onpacket(type, lambda do |packet|
                    @handles[type].each do |h|
                        if h.call(packet, r); break; end
                    end
                end)
            end
        end

        @handles[type].push(f)
    end
end
