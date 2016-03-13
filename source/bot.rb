# A bot responds to low-level triggers from a collection of rooms
class Bot
    attr_reader :basename

    attr_accessor :group

    def initialize(name)
        @group = nil

        @basename = name
        @rooms = []

        @onnew = []
    end

    public
    # Convert to a hash
    def to_h()
        return {
            "nick" => @basename,
            "rooms" => room_names,
        }
    end

    # Convert from a hash
    def self.from_h(h)
        bot = Bot.new(h["nick"])
        h["rooms"].each do |r|
            bot.add_room(Room.new(r))
        end
        return bot
    end

    # Add a room to the collection for monitoring
    def add_room(room)
        if not room.exists
            return false
        end

        @onnew.each do |on|
            on.call(room)
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

    # Add a callback for when a room is added
    def new_room(&blk)
        @rooms.each do |r|
            blk.call(r)
        end

        @onnew.push(blk)
    end

    # Create an event for the connection
    def connection_event(name, &blk)
        new_room do |room|
            room.connection.onevent(name) do |message|
                blk.call(message, room)
            end
        end
    end

    # Create an event for broadcasts
    def broadcast_event(&blk)
        new_room do |room|
            room.broadcast.onevent do |message|
                blk.call(message, room)
            end
        end
    end
end
