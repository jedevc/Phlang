require_relative 'phlangbot'

# Load bots from 'place' with the desired 'extension'
def load_local_bots(place, extension="phlang")
    target = File.join(Dir.pwd, place)

    bot_sources = {}

    Dir.glob(File.join(target, "*.#{extension}")) do |filename|
        File.open(filename, 'r') do |file|
            source = file.read
            bot_sources[File.basename(filename, ".#{extension}")] = source
        end
    end

    bots = []
    bot_sources.each_key do |k|
        b = PhlangBot.new(k, bot_sources[k], NORMAL_CONFIG)
        bots.push(b)
    end
    return bots
end

def load_bots(place, options, extension="phlang")
    base = File.join(Dir.pwd, place)

    sources = {}

    options.each do |opt|
        target = File.join(base, opt, "*.#{extension}")
        Dir.glob(target) do |filename|
            File.open(filename, 'r') do |file|
                source = file.read
                sources[File.basename(filename, ".#{extension}")] = source
            end
        end
    end

    bots = []
    sources.each_key do |k|
        b = PhlangBot.new(k, sources[k], NORMAL_CONFIG)
        bots.push(b)
    end
    return bots
end
