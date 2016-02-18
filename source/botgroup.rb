require 'json'

require_relative 'phlangbot'

class PhlangBotGroup
    def initialize()
        @bots = []
    end

    public
    # Add a bot to the group
    def add(bot)
        bot.group = self
        @bots.push(bot)
    end

    def save()
        data = @bots.map {|b| b.to_h}
        raw = JSON.pretty_generate(data)

        now = Time.now.utc.strftime("%Y-%m-%d@%H:%M:%S")
        filename = File.join("snapshots", now)
        File.open(filename, 'w') do |file|
            file.write(raw)
        end

        latest = File.join("snapshots", "latest")

        if File.symlink?(latest)
            File.delete(latest)
        end
        File.symlink(filename, latest)
    end

    def recover()
        raw = ""
        filename = File.readlink(File.join("snapshots", "latest"))
        File.open(filename, 'r') do |file|
            raw = file.read()
        end
        data = JSON.load(raw)
        data.each do |d|
            @bots.push(PhlangBot.from_h(d, PhlangBotConfig.new(FULL_BUILTINS, MINIMAL_TRIGGERS, MINIMAL_RESPONSES)))
        end
    end

    # Remove a bot from the group
    def remove(bot)
        bot.group = nil
        bot.remove_all_rooms()
        @bots.delete(bot)
    end

    def clear()
        @bots.each do |bot|
            bot.group = nil
            bot.remove_all_rooms()
        end
        @bots.clear()
    end

    # Iteration helper
    def each()
        @bots.each do |b|
            yield b
        end
    end
end
