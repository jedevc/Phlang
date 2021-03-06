require_relative 'phlangbot'
require_relative 'config'

def load_source(places)
    sources = {}

    places.each do |place|
        Dir.glob(place) do |filename|
            if File.file?(filename)
                File.open(filename, 'r') do |file|
                    source = file.read
                    sources[File.basename(filename, '.*')] = source
                end
            elsif File.directory?(filename)
                sources.merge!(load_source([File.join(filename, '*')]))
            end
        end
    end

    return sources
end

def load_bots(source, creator, conf=nil)
    if conf == nil
        conf = LOW_SECURITY
    end

    bots = []
    source.each_key do |k|
        b = PhlangBot.new(k, source[k], conf, creator)
        bots.push(b)
    end
    return bots
end
