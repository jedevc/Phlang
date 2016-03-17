require 'json'
require 'yaml/store'

require_relative 'phlangbot'

class BotGroup
    def initialize()
        @bots = []
        @cempty = true

        @store = nil
    end

    public
    def empty?
        return (@bots.length == 0 and @cempty)
    end

    # Add a bot to the group
    def add(bot)
        bot.group = self
        @bots.push(bot)
    end

    # Create a snapshot
    def save(name)
        filename = File.join("snapshots", name)
        @store = YAML::Store.new(filename)

        @store.transaction do
            @store["bots"] = @bots.map {|b| b.to_h}
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

        # Load the store
        @store = YAML::Store.new(filename)

        @cempty = false
        @store.transaction do
            clear()
            @store["bots"].each do |d|
                add(PhlangBot.from_h(d))
            end
        end
        @cempty = true
    end

    # Remove a bot from the group
    def remove(bot)
        bot.group = nil
        bot.remove_all_rooms()
        @bots.delete(bot)
    end

    # Remove all bots from the group
    def clear()
        @bots.each do |bot|
            bot.group = nil
            bot.remove_all_rooms()
        end
        @bots.clear()
    end

    def each()
        @bots.each do |b|
            yield b
        end
    end
end
