require_relative 'logservice'

require_relative 'room'
require_relative 'bot'

require_relative 'parser'

class PhlangBot < Bot
    attr_reader :config

    attr_accessor :variables

    def initialize(name, code, creator, config)
        super(name)
        @config = config

        @paused = []
        @spam = {}

        @creator = creator
        @code = code

        admin_commands() if @config.builtins.admin
        util_commands() if @config.builtins.util
        load_code(Parser.new(code, @config.allowed_triggers, @config.allowed_responses).parse())
        info_commands() if @config.builtins.info

        @variables = {}
    end

    def to_h()
        return {
            "nick" => @basename,
            "rooms" => room_names,
            "code" => @code,
            "creator" => @creator,
            "config" => @config.to_h,
            "variables" => @variables
        }
    end

    def self.from_h(h)
        bot = PhlangBot.new(h["nick"], h["code"], h["creator"], PhlangBotConfig.from_h(h["config"]))
        h["rooms"].each do |r|
            bot.add_room(Room.new(r))
        end
        bot.variables = h["variables"]
        return bot
    end

    def load_code(blocks)
        blocks.each do |b|
            tr = nil

            begin
                tr = b.export(@config.allowed_triggers, @config.allowed_responses)
            rescue RuntimeError => e
                LogService.warn "error parsing code: #{e.inspect}"
            end

            if tr
                trigger, response = tr
                trigger.add(self, response)
            end
        end
    end

    def variables(room)
        if !@variables.has_key?(room.name)
            @variables[room.name] = {}
        end
        return @variables[room.name]
    end

    def pause(room, pos=true)
        if pos
            @paused.push(room)
        else
            @paused.delete(room)
            @spam.delete(room)
        end
    end

    def paused?(room)
        return @paused.include? room
    end

    def spam(room, amount=1)
        if !@config.spam_limit.nil?
            if !@spam.has_key? room
                @spam[room] = amount
                room.timer.onevent(Time.now + 60) do
                    @spam.delete(room)
                end
            else
                @spam[room] += amount
            end

            if @spam[room] >= @config.spam_limit
                room.send_message("/me has been paused (possible spam attack).")
                pause(room)
                return true
            else
                return false
            end
        end
    end

    def connection_event(name, &blk)
        new_room do |room|
            room.connection.onevent(name) do |message|
                blk.call(message, room)
            end
        end
    end

    def broadcast_event(&blk)
        new_room do |room|
            room.broadcast.onevent do |message|
                blk.call(message, room)
            end
        end
    end

    def admin_commands()
        connection_event("send-event") do |message, room|
            name = room.nick
            if /\A!restore @#{name}\Z/.match(message["content"]) and paused? room
                pause(room, false)
                room.send_message("/me is now restored.", message["id"])
                next true
            elsif /\A!pause @#{name}\Z/.match(message["content"]) and !paused? room
                room.send_message("/me is now paused.", message["id"])
                pause(room)
                next true
            elsif /\A!kill @#{name}\Z/.match(message["content"])
                room.send_message("/me is exiting.", message["id"])
                remove_room(room)

                pause(room, false)
                @variables.delete(room)

                if room_names.length == 0
                    @group.remove(self)
                end
                next true
            else
                next false
            end
        end
    end

    def util_commands()
        connection_event("send-event") do |message, room|
            name = room.nick
            if !paused? room
                if /\A!sendbot @#{name} &(\S+)\Z/.match(message["content"])
                    newroom = /^!sendbot @#{name} &(\S+)$/.match(message["content"])[1]
                    if add_room(Room.new(newroom))
                        room.send_message("/me has been sent to &#{newroom}.", message["id"])
                    else
                        room.send_message("/me could not find &#{newroom}.", message["id"])
                    end
                    next true
                elsif /\A!code @#{name}\Z/.match(message["content"])
                    room.send_message(@code, message["id"])
                    next true
                end
            end
            next false
        end
    end

    def info_commands()
        connection_event("send-event") do |message, room|
            name = room.nick
            content = message["content"]
            if !paused? room
                if /\A!ping(?: @#{name})?\Z/.match(content)
                    room.send_message("Pong!", message["id"])
                    next true
                elsif /\A!help @#{name}\Z/.match(content)
                    room.send_message(
                        "@#{@basename} is a bot created by '#{@creator}' using a top secret project.\n\n" \
                        "@#{@basename} responds to !ping, !help, !kill, !pause (and !restore)." \
                    , message["id"])
                    next true
                elsif /\A!help\Z/.match(content)
                    room.send_message("#{@basename} is a bot created by '#{@creator}'.", message["id"])
                    next true
                elsif /\A!creator @#{name}\Z/.match(message["content"])
                    room.send_message(@creator, message["id"])
                    next true
                end
            end
            next false
        end
    end
end
