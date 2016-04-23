require_relative 'botstore'

class BotGroup
    def initialize(bottype)
        # Required for loading snapshots. Should inherit from Bot.
        @bottype = bottype

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
        if @store
            @store.transaction do
                @store[bot.basename] = bot.to_h
            end
        end
    end

    # Force an update of the store
    def force(bot=nil)
        if !@store.nil?
            @store.transaction do
                if bot.nil?
                    names = @bots.map {|b| b.basename}
                    bhs = @bots.map {|b| b.to_h}

                    Hash[names.zip(bhs)].each do |k, v|
                        @store[k] = v
                    end
                else
                    @store[bot.basename] = bot.to_h
                end
            end
        end
    end

    # Create a snapshot
    def save(name)
        filename = File.join("snapshots", name)

        @store = BotStore.new(filename)

        force()

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

        bs = []
        @store.transaction do
            @store.roots.each do |k|
                bs.push(@bottype.from_h(@store[k]))
            end
        end

        @cempty = false
        clear()
        bs.each do |v|
            add(v)
        end
        @cempty = true
    end

    # Remove a bot from the group
    def remove(bot)
        bot.group = nil
        bot.remove_all_rooms()
        @bots.delete(bot)

        if !@store.nil?
            @store.transaction do
                @store.delete(bot.basename)
            end
        end
    end

    # Remove all bots from the group
    def clear()
        @bots.each do |bot|
            bot.group = nil
            bot.remove_all_rooms()
        end
        @bots.clear()

        if !@store.nil?
            @store.transaction do
                @store.roots.each do |r|
                    @store.delete(r)
                end
            end
        end
    end

    def each()
        @bots.each do |b|
            yield b
        end
    end
end
