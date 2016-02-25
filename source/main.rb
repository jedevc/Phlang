require_relative 'local'
require_relative 'botgroup'

require_relative 'logservice'

require 'optparse'

Thread.abort_on_exception = true

def main(opts)
    LogService.provide(create_log(Logger::INFO, opts[:logging]))

    begin
        bs = PhlangBotGroup.new()

        places = opts[:file]
        source = load_source(places)
        loaded = load_bots(source, opts[:config])
        if loaded.length > 0
            loaded.each do |b|
                bs.add(b)
            end
        else
            LogService.get.fatal "could not find any bots at #{places}"
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
    options = {
        :file => [],
        :room => "costofcivilization",
        :logging => STDOUT,
        :config => nil
    }

    # Parse command line args
    OptionParser.new do |opts|
        opts.banner = "Usage: ./run_phlang.sh [options]"

        opts.on("-f FILE", "--file FILE", "Where to load bots from") do |v|
            options[:file].push(v)
        end

        opts.on("-r ROOM", "--room ROOM", "Room to spawn bots in") do |v|
            options[:room] = v
        end

        opts.on("-l LOGFILE", "--log LOGFILE", "File to output logs to") do |v|
            options[:logging] = v
        end

        opts.on("-s SECURITY", "--security SECURITY", "Security setting to use") do |v|
            if v == "low"
                options[:config] = PhlangBotConfig.new(MINIMAL_BUILTINS, FULL_TRIGGERS, FULL_RESPONSES, true)
            elsif v == "high"
                options[:config] = PhlangBotConfig.new(FULL_BUILTINS, MINIMAL_TRIGGERS, MINIMAL_RESPONSES, true)
            end
        end
    end.parse!

    # Call main function
    main(options)
end
