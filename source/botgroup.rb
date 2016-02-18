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

    # Create a snapshot
    def save(name)
        # Prepare the data
        data = @bots.map {|b| b.to_h}
        raw = JSON.pretty_generate(data)

        # Write the snapshot
        filename = File.join("snapshots", name)
        File.open(filename, 'w') do |file|
            file.write(raw)
        end

        # Symlink 'latest' to the new file
        latest = File.join("snapshots", "latest")
        if File.symlink?(latest)
            File.delete(latest)
        end
        File.symlink(filename, latest)
    end

    # Recover a snapshot
    def recover(form="latest")
        # Work out the filepath
        filename = File.join("snapshots", form)
        if File.symlink?(filename)
            filename = File.readlink(filename)
        end
        if !File.exists?(filename)
            return
        end

        # Get the raw data
        raw = ""
        File.open(filename, 'r') do |file|
            raw = file.read()
        end
        data = JSON.load(raw)

        # Add the data to the group
        data.each do |d|
            @bots.push(PhlangBot.from_h(d))
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
