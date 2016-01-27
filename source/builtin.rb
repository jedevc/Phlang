# Create the default builtin commands for bots that they should all implement
def builtin(botname, creator)
    return lambda do |message, room|
        content = message["content"]
        if /^!ping(?: @#{botname})?$/.match(content)
            room.send_message("Pong!", message["id"])
            return true
        elsif /^!help @#{botname}$/.match(content)
            room.send_message(
                "#{botname} is a bot created by '#{creator}' using a top secret project.\n\n" \
                "@#{botname} responds to !ping, !help @#{botname}, !kill, !pause (and !restore)." \
            , message["id"])
            return true
        elsif /^!help$/.match(content)
            room.send_message("#{botname} is a bot created by '#{creator}'.", message["id"])
            return true
        end
    end
end
