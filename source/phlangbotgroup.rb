class PhlangBotGroup
    def initialize()
        @bots = []
    end

    public
    # Add a bot to the group
    def add(bot)
        @bots.push(bot)
        bot.add_handle("rooms-gone", lambda do
            remove(bot)
        end)
    end

    # Remove a bot from the group
    def remove(bot)
        bot.remove_all_rooms()
        @bots.delete(bot)
    end

    # Iteration helper
    def each()
        @bots.each do |b|
            yield b
        end
    end
end
