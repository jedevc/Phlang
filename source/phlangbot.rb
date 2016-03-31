require_relative 'logservice'

require_relative 'room'
require_relative 'bot'

require_relative 'parser'

class PhlangBot < Bot
    attr_reader :config

    def initialize(name, code, config, creator="")
        super(name)
        @config = config

        @paused = []
        @spam = {}
        @has_responded = {}

        @creator = creator
        @code = code

        admin_commands() if @config.builtins.admin
        util_commands() if @config.builtins.util
        load_code(Parser.new(code, @config.allowed_triggers, @config.allowed_responses).parse())
        info_commands() if @config.builtins.info
        connection_event("send-event") {|m, r| @has_responded[r] = false} # Reset responses

        @variables = {}
    end

    public
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

    # Get the variables for a specific room
    def variables(room)
        if !@variables.has_key?(room.name)
            @variables[room.name] = {}
        end
        return @variables[room.name]
    end

    # Pause a room
    def pause(room, pos=true)
        if pos
            @paused.push(room)
        else
            @paused.delete(room)
            @spam.delete(room)
        end
    end

    # See if a room is paused
    def paused?(room)
        return @paused.include? room
    end

    # Increment the spam counter
    def spam(room, amount=1)
        @has_responded[room] = true
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

    private
    # Load code from blocks of code
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

    # Administration commands
    def admin_commands()
        connection_event("send-event") do |message, room|
            name = room.nick
            if /\A!restore @#{name}\Z/.match(message["content"]) and paused? room
                pause(room, false)
                room.send_message("/me is now restored.", message["id"])
            elsif /\A!pause @#{name}\Z/.match(message["content"]) and !paused? room
                room.send_message("/me is now paused.", message["id"])
                pause(room)
            elsif /\A!kill @#{name}\Z/.match(message["content"])
                room.send_message("/me is exiting.", message["id"])
                remove_room(room)

                pause(room, false)
                @variables.delete(room)

                @group.force(self)

                if room_names.length == 0
                    @group.remove(self)
                end
            end
        end
    end

    # Various utility commands
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
                    @group.force(self)
                elsif /\A!code @#{name}\Z/.match(message["content"])
                    room.send_message(@code, message["id"])
                end
            end
        end
    end

    # Information commands
    def info_commands()
        connection_event("send-event") do |message, room|
            name = room.nick
            content = message["content"]
            if !paused? room and !@has_responded[room]
                if /\A!ping(?: @#{name})?\Z/.match(content)
                    room.send_message("Pong!", message["id"])
                elsif /\A!help @#{name}\Z/.match(content)
                    room.send_message(
                        "@#{@basename} is a bot created by '#{@creator}' using Phlang.\n\n" \
                        "@#{@basename} responds to !ping, !help, !kill, !pause (and !restore)." \
                    , message["id"])
                elsif /\A!help\Z/.match(content)
                    room.send_message("#{@basename} is a bot created by '#{@creator}'.", message["id"])
                elsif /\A!creator @#{name}\Z/.match(message["content"]) and @creator.length > 0
                    room.send_message(@creator, message["id"])
                end
            end
        end
    end
end
