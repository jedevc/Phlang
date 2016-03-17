require_relative 'triggers'
require_relative 'responses'

class TriggerFactory
    @@triggers = {
        "start" => StartTrigger.method(:new),
        "msg" => MessageTrigger.method(:new),
        "receive" => BroadcastTrigger.method(:new),
        "timer" => TimerTrigger.method(:new),
        "ptimer" => PushTimerTrigger.method(:new),
        "every" => EveryTrigger.method(:new)
    }

    def self.build(t, args)
        return @@triggers[t].call(args)
    end

    def self.triggers
        return @@triggers
    end
end

class ResponseFactory
    @@responses = {
        "send" => SendResponse.method(:new),
        "reply" => ReplyResponse.method(:new),
        "broadcast" => BroadcastResponse.method(:new),
        "nick" => NickResponse.method(:new),
        "set" => SetResponse.method(:new),
        "breakif" => BreakResponse.method(:new)
    }

    @@advanced_responses = {
        "create" => CreateResponse.method(:new),
        "log" => LogResponse.method(:new),
        "list" => ListResponse.method(:new),
        "save" => SaveResponse.method(:new),
        "recover" => RecoverResponse.method(:new)
    }

    def self.build(t, args)
        complete = @@responses.merge(@@advanced_responses)
        return complete[t].call(args)
    end

    def self.responses
        return @@responses
    end

    def self.advanced_responses
        return @@advanced_responses
    end
end
