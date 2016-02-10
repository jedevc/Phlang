require_relative 'code'
require_relative 'room'

require_relative 'triggers'
require_relative 'responses'

class PhlangBot < Bot
    def initialize(name, code, config, creator="local")
        super(name)
        @config = config

        @paused = []
        @creator = creator
        @code = code

        admin_commands() if @config.builtins.admin
        util_commands() if @config.builtins.util
        load_code(CodeParser.new(code).parse(@config.triggers, @config.responses))
        info_commands() if @config.builtins.info

        @variables = {}
    end

    def load_code(blocks)
        blocks.each do |b|
            tr = b.export(@config.triggers, @config.responses)
            if tr
                trigger, response = tr
                trigger.add(self, response)
            end
        end
    end

    def fork_new_bot(nick, code, roomname, creator="local")
        conf = PhlangBotConfig.new(FULL_BUILTINS, MINIMAL_TRIGGERS, MINIMAL_RESPONSES)

        nb = PhlangBot.new(nick, code, conf, creator)

        r = Room.new(roomname)
        nb.add_room(r)

        @group.add(nb)
    end

    def msg_handle(&blk)
        add_handle("send-event") do |message, room|
            # Check that message was not triggered by bot
            if message
                next nil if message["sender"]["id"].split(':')[0] == "bot"
            end
            next blk.call(message, room)
        end
    end

    def start_handle(&blk)
        add_handle("hello-event") do |message, room|
            next blk.call(room)
        end
    end

    def variables(room)
        if !@variables.has_key?(room)
            @variables[room] = {}
        end
        return @variables[room]
    end

    def admin_commands()
        msg_handle do |message, room|
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
        msg_handle do |message, room|
            name = room.nick
            if /^!sendbot @#{name} &(\S+)$/.match(message["content"])
                room = /^!sendbot @#{name} &(\S+)$/.match(message["content"])[1]
                add_room(Room.new(room))
                next true
            end
        end
    end

    def info_commands()
        msg_handle do |message, room|
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
