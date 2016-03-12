class Message
    attr_reader :content
    attr_reader :sender
    attr_reader :senderid
    attr_reader :id
    attr_reader :time

    def initialize(*args)
        if args.length == 1
            packet = args[0]
            packet.default = {}
            @content = packet["content"]
            @sender = packet["sender"]["name"]
            @senderid = packet["sender"]["id"]
            @id = packet["id"]
            @time = packet["time"]
        else
            @content, @sender, @id, @time = args
        end
    end
end
