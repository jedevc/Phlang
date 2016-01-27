require_relative 'local'
require_relative 'metabot'
require_relative 'phlangbotgroup'

require_relative 'botbot_expression'

Thread.abort_on_exception = true

def main(args)
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
end

if __FILE__ == $0
    main(ARGV)
end
