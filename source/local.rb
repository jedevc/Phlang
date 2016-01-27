require_relative 'phlangbot'

# Load bots from 'place' with the desired 'extension'
def load_local_bots(place="bots", extension="phlang")
    target = File.join(Dir.pwd, place)

    bot_sources = {}

    Dir.glob(File.join(target, "*.#{extension}")) do |filename|
        File.open(filename, 'r') do |file|
            bot_sources[File.basename(filename, ".#{extension}")] = file.read.gsub("\n", " ")
        end
    end

    bots = []
    bot_sources.each_key do |k|
        b = PhlangBot.new(k, bot_sources[k])
        bots.push(b)
    end
    return bots
end
