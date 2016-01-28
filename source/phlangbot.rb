require_relative 'code'
require_relative 'room'

class PhlangBotConfig
    attr_reader :admin
    attr_reader :util
    attr_reader :info

    def initialize(admin, util, info)
        @admin = admin
        @util = util
        @info = info
    end
end

MINIMAL_CONFIG = PhlangBotConfig.new(false, false, false)
NORMAL_CONFIG = PhlangBotConfig.new(false, false, true)
ADMIN_CONFIG = PhlangBotConfig.new(true, true, true)

class PhlangBot < Bot
    def initialize(name, code, config, creator="local")
        super(name)

        @paused = []

        @code = code
        @creator = creator

        admin_commands() if config.admin
        util_commands() if config.util

        # Coded commands
        triggers = Code.new(code).parse
        triggers.each do |t|
            add_handle("send-event", lambda {|m, r| t.attempt(m, r)})
        end

        info_commands() if config.info
    end

    def admin_commands()
        add_handle("send-event", lambda do |message, room|
            if /^!kill @#{@name}$/.match(message["content"])
                room.send_message("/me is exiting.", message["id"])
                remove_room(room)
                if room_count == 0
                    trigger("rooms-gone")
                end
                return true
            elsif !@paused.include?(room) && /^!pause @#{@name}$/.match(message["content"])
                room.send_message("/me is now paused.", message["id"])
                @paused.push(room)
                return true
            elsif @paused.include?(room) && /^!restore @#{@name}$/.match(message["content"])
                room.send_message("/me is now restored.", message["id"])
                @paused.delete(room)
                return true
            elsif @paused.include?(room)
                return true
            end
        end)
    end

    def util_commands()
        add_handle("send-event", lambda do |message, room|
            if /^!sendbot @#{@name} &(\S+)$/.match(message["content"])
                room = /^!sendbot @#{@name} &(\S+)$/.match(message["content"])[1]
                add_room(Room.new(room))
                return true
            end
        end)
    end

    def info_commands()
        add_handle("send-event", lambda do |message, room|
            content = message["content"]
            if /^!ping(?: @#{@name})?$/.match(content)
                room.send_message("Pong!", message["id"])
                return true
            elsif /^!help @#{@name}$/.match(content)
                room.send_message(
                    "#{@name} is a bot created by '#{@creator}' using a top secret project.\n\n" \
                    "@#{@name} responds to !ping, !help, !kill, !pause (and !restore)." \
                , message["id"])
                return true
            elsif /^!help$/.match(content)
                room.send_message("#{@name} is a bot created by '#{@creator}'.", message["id"])
                return true
            end
        end)
    end
end
