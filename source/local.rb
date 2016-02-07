require_relative 'phlangbot'
require_relative 'config'

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

    conf = PhlangBotConfig.new(MINIMAL_BUILTINS, FULL_TRIGGERS, FULL_RESPONSES)

    bots = []
    sources.each_key do |k|
        b = PhlangBot.new(k, sources[k], conf)
        bots.push(b)
    end
    return bots
end
