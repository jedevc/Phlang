require_relative 'code'
require_relative 'room'

class PhlangBot < Bot
    def initialize(name, code, creator="local", builtins=true)
        super(name)

        @paused = []

        # Admin commands
        add_handle("send-event", lambda do |message, room|
            if /^!kill @#{@name}$/.match(message["content"])
                room.send_message("/me is exiting.", message["id"])
                remove_room(room)
                if room_count == 0
                    trigger("rooms-gone")
                end
                return true
            elsif !@paused.include?(room.room) && /^!pause @#{@name}$/.match(message["content"])
                room.send_message("/me is now paused.", message["id"])
                @paused.push(room.room)
                return true
            elsif @paused.include?(room.room) && /^!restore @#{@name}$/.match(message["content"])
                room.send_message("/me is now restored.", message["id"])
                @paused.delete(room.room)
                return true
            elsif @paused.include?(room.room)
                return true
            elsif /^!sendbot @#{@name} &(\S+)$/.match(message["content"])
                room = /^!sendbot @#{@name} &(\S+)$/.match(message["content"])[1]
                add_room(Room.new(room))
            end
        end)

        # Coded commands
        triggers = Code.new(code).parse
        triggers.each do |t|
            add_handle("send-event", lambda {|m, r| t.attempt(m, r)})
        end

        # Builtin commands
        if builtins
            add_handle("send-event", builtin(name, creator))
        end
    end
end
