class BotGroup
    def initialize()
        @bots = []
    end

    public
    # Add a bot to the group
    def add(bot)
        bot.group = self
        @bots.push(bot)
    end

    # Remove a bot from the group
    def remove(bot)
        bot.group = nil
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
