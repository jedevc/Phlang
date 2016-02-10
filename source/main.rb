require_relative 'local'
require_relative 'botgroup'

require_relative 'logservice'

require 'optparse'

Thread.abort_on_exception = true

def main(opts)
    LogService.provide(create_log(:info, opts[:logging]))

    begin
        bs = BotGroup.new()

        base, options = "bots", opts[:file]
        source = load_source(base, options)
        loaded = load_bots(source)
        if loaded.length > 0
            loaded.each do |b|
                bs.add(b)
            end
        else
            LogService.get.fatal "could not find any bots in (#{base}/#{options})"
            return
        end

        bs.each do |b|
            r = Room.new(opts[:room])
            b.add_room(r)
        end

        sleep
    rescue => e
        backtrace = (e.backtrace.map {|l| "\t#{l}"}).join("\n")
        LogService.get.fatal "unhandled exception: #{e.inspect} in \n#{backtrace}"
    end
end

if __FILE__ == $0
    # Set default args
    options = {:file => [], :room => "costofcivilization", :logging => STDOUT}

    # Parse command line args
    OptionParser.new do |opts|
        opts.banner = "Usage: ./run_phlang.sh [options]"

        opts.on("-fFILE", "--file=FILE", "File in bots/ to load from") do |v|
            options[:file].push(v)
        end

        opts.on("-rROOM", "--room=ROOM", "Room to spawn bots in") do |v|
            options[:room] = v
        end

        opts.on("-lLOGFILE", "--logfile=LOGFILE", "File to output logs to.") do |v|
            options[:logging] = v
        end
    end.parse!

    # Call main function
    main(options)
end
