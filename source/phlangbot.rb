require_relative 'code'
require_relative 'room'

require_relative 'triggers'
require_relative 'responses'

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

        load_code(CodeParser.new(code).parse(TRIGGERS, RESPONSES))

        info_commands() if config.info
    end

    def load_code(blocks)
        blocks.each do |b|
            trigger, response = b.export(TRIGGERS, RESPONSES)
            trigger.add(self, response)
        end
    end

    def admin_commands()
        add_handle("send-event") do |message, room|
            name = room.nick
            if /^!kill @#{name}$/.match(message["content"])
                room.send_message("/me is exiting.", message["id"])
                remove_room(room)
                if room_count == 0
                    trigger("rooms-gone")
                end
                next true
            elsif !@paused.include?(room) && /^!pause @#{name}$/.match(message["content"])
                room.send_message("/me is now paused.", message["id"])
                @paused.push(room)
                next true
            elsif @paused.include?(room) && /^!restore @#{name}$/.match(message["content"])
                room.send_message("/me is now restored.", message["id"])
                @paused.delete(room)
                next true
            elsif @paused.include?(room)
                next true
            end
        end
    end

    def util_commands()
        add_handle("send-event") do |message, room|
            name = room.nick
            if /^!sendbot @#{name} &(\S+)$/.match(message["content"])
                room = /^!sendbot @#{name} &(\S+)$/.match(message["content"])[1]
                add_room(Room.new(room))
                next true
            end
        end
    end

    def info_commands()
        add_handle("send-event") do |message, room|
            name = room.nick
            content = message["content"]
            if /^!ping(?: @#{name})?$/.match(content)
                room.send_message("Pong!", message["id"])
                next true
            elsif /^!help @#{name}$/.match(content)
                room.send_message(
                    "@#{@basename} is a bot created by '#{@creator}' using a top secret project.\n\n" \
                    "@#{@basename} responds to !ping, !help, !kill, !pause (and !restore)." \
                , message["id"])
                next true
            elsif /^!help$/.match(content)
                room.send_message("#{@basename} is a bot created by '#{@creator}'.", message["id"])
                next true
            end
        end
    end
end
