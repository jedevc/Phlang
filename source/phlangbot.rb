require_relative 'logservice'

require_relative 'phlangroom'
require_relative 'bot'

require_relative 'parser'

class PhlangBot < Bot
    attr_reader :config

    def initialize(name, code, config, creator="")
        super(name)
        @config = config

        @creator = creator
        @code = code

        @help = []
        @help << "@#{name} is a bot created by '#{creator}' using Phlang."
        @help << "@#{name} responds to !ping, help, and (possibly) !creator."
        @help << "@#{name} may also be !pause'd, !restore'd or !kill'd." if @config.builtins.admin

        new_room do |room|
            admin_commands(room) if @config.builtins.admin
            util_commands(room) if @config.builtins.util
            load_code(code, room)
            info_commands(room) if @config.builtins.info

            # Reset responsed switch
            room.connection.onevent("send-event") {|_| room.responded = false}
        end
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
            bot.add_room_name(r)
        end
        return bot
    end

    def add_room_name(name, password=nil)
        return add_room(PhlangRoom.new(name, password, @config.spam_limit))
    end

    private
    # Load triggers from code
    def load_code(code, room)
        begin
            root = Parser.new(code, @config.allowed_triggers, @config.allowed_responses).parse()
        rescue RuntimeError => e
            LogService.warn(e)
        else
            context = ExecutionContext.new

            root.perform(context)

            context.triggers.each do |trig|
                trig.call(room, self)
            end
        end
    end

    # Administration commands
    def admin_commands(room)
        room.connection.onevent("send-event") do |message|
            name = room.nick
            if /\A!restore @#{name}\Z/.match(message["content"]) and room.paused
                room.paused = false
                room.send_message("/me is now restored.", message["id"])
            elsif /\A!pause @#{name}\Z/.match(message["content"]) and !room.paused
                room.paused = true
                room.send_message("/me is now paused.", message["id"])
            elsif /\A!kill @#{name}\Z/.match(message["content"])
                room.send_message("/me is exiting.", message["id"])
                remove_room(room)

                if room_names.length == 0
                    @group.remove(self)
                else
                    @group.force(self)
                end
            end
        end
    end

    # Various utility commands
    def util_commands(room)
        room.connection.onevent("send-event") do |message|
            name = room.nick
            if !room.paused
                if /\A!sendbot @#{name} &(\S+)\Z/.match(message["content"])
                    newroom = /^!sendbot @#{name} &(\S+)$/.match(message["content"])[1]
                    if add_room_name(newroom)
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
    def info_commands(room)
        room.connection.onevent("send-event") do |message|
            name = room.nick
            content = message["content"]
            if !room.paused and !room.responded
                if /\A!ping(?: @#{name})?\Z/.match(content)
                    room.send_message("Pong!", message["id"])
                elsif /\A!help @#{name}\Z/.match(content)
                    room.send_message(@help.join("\n"), message["id"])
                elsif /\A!help\Z/.match(content)
                    room.send_message(@help[0], message["id"])
                elsif /\A!creator @#{name}\Z/.match(message["content"]) and @creator.length > 0
                    room.send_message(@creator, message["id"])
                end
            end
        end
    end
end
