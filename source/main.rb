require_relative 'local'
require_relative 'metabot'
require_relative 'phlangbotgroup'

require_relative 'logservice'

Thread.abort_on_exception = true

def main(args)
    LogService.provide(create_log(:info))

    begin
        bs = PhlangBotGroup.new()

        if args[0] == "metabot"
            bot = MetaBot.new()
            bs.add(bot)
        elsif args[0] == "local"
            load_local_bots().each do |b|
                bs.add(b)
            end
        else
            return
        end

        bs.each do |b|
            r = Room.new("costofcivilization")
            b.add_room(r)
        end

        sleep
    rescue => e
        backtrace = (e.backtrace.map {|l| "\t#{l}"}).join("\n")
        LogService.get.fatal "unhandled exception: #{e.inspect} in \n#{backtrace}"
    end
end

if __FILE__ == $0
    main(ARGV)
end
