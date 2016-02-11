require_relative 'phlangbot'
require_relative 'config'

def load_source(place, subs, extension="phlang")
    sources = {}

    subs.each do |s|
        Dir.glob(File.join(place, s + ".#{extension}")) do |filename|
            if File.file?(filename)
                File.open(filename, 'r') do |file|
                    source = file.read
                    sources[File.basename(filename, ".#{extension}")] = source
                end
            end
        end

        Dir.glob(File.join(place, s)) do |filename|
            if File.directory?(filename)
                sources.merge!(load_source(filename, ["*"], extension))
            end
        end
    end

    return sources
end

def load_bots(source)
    conf = PhlangBotConfig.new(MINIMAL_BUILTINS, FULL_TRIGGERS, FULL_RESPONSES, true)

    bots = []
    source.each_key do |k|
        b = PhlangBot.new(k, source[k], conf)
        bots.push(b)
    end
    return bots
end
