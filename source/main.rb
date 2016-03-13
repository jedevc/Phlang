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
        if source.length > 0
            loaded = load_bots(source, opts[:creator], opts[:config])
            loaded.each do |b|
                bs.add(b)
            end
        else
            LogService.fatal "could not find any bots at #{places}"
            return
        end

        bs.each do |b|
            r = Room.new(opts[:room], opts[:password])
            b.add_room(r)
        end

        sleep
    rescue => e
        LogService.fatal "unhandled exception: #{e.inspect} in\n#{e.backtrace[0]}"
    end
end

if __FILE__ == $0
    # Set default args
    options = {
        :file => [],
        :room => "costofcivilization",
        :password => nil,
        :logging => STDOUT,
        :creator => "local",
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

        opts.on("-p PASSWORD", "--password PASSWORD", "Password for the room") do |v|
            options[:password] = v
        end

        opts.on("-l LOGFILE", "--log LOGFILE", "File to output logs to") do |v|
            options[:logging] = v
        end

        opts.on("-c CREATOR", "--creator CREATOR", "Who the bot should say their creator is") do |v|
            options[:creator] = v
        end

        opts.on("-s SECURITY", "--security SECURITY", "Security setting to use") do |v|
            if v == "low"
                options[:config] = LOW_SECURITY
            elsif v == "high"
                options[:config] = HIGH_SECURITY
            end
        end
    end.parse!

    # Call main function
    main(options)
end
