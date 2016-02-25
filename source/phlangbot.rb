require_relative 'room'
require_relative 'bot'

require_relative 'parser'

class PhlangBot < Bot
    def initialize(name, code, config, creator="local")
        super(name)
        @config = config

        @paused = []
        @creator = creator
        @code = code

        admin_commands() if @config.builtins.admin
        util_commands() if @config.builtins.util
        load_code(Parser.new(code, @config.allowed_triggers, @config.allowed_responses).parse())
        info_commands() if @config.builtins.info

        @variables = {}
    end

    def load_code(blocks)
        blocks.each do |b|
            tr = b.export(@config.allowed_triggers, @config.allowed_responses)
            if tr
                trigger, response = tr
                trigger.add(self, response)
            end
        end
    end

    def to_h()
        return {
            "nick" => @basename,
            "rooms" => room_names,
            "code" => @code,
            "creator" => @creator,
            "config" => @config.to_h
        }
    end

    def self.from_h(h)
        bot = PhlangBot.new(h["nick"], h["code"], PhlangBotConfig.from_h(h["config"]), h["creator"])
        h["rooms"].each do |r|
            bot.add_room(Room.new(r))
        end
        return bot
    end

    def msg_handle(&blk)
        add_handle("send-event") do |message, room|
            # Check that message was not triggered by bot
            if message and (message["sender"]["id"].split(':')[0] != "bot" || @config.botinteraction)
                next blk.call(message, room)
            else
                next nil
            end
        end
    end

    def start_handle(&blk)
        add_handle("snapshot-event") do |message, room|
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
                if room_names.length == 0
                    @group.remove(self)
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
                newroom = /^!sendbot @#{name} &(\S+)$/.match(message["content"])[1]
                add_room(Room.new(newroom))
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
