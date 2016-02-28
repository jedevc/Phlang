require_relative 'triggers'
require_relative 'responses'

class TriggerFactory
    @@triggers = {
        "start" => lambda do |args| return StartTrigger.new(args) end,
        "msg" => lambda do |args| return MessageTrigger.new(args) end,
        "timer" => lambda do |args| return TimerTrigger.new(args) end,
        "ptimer" => lambda do |args| return PushTimerTrigger.new(args) end,
        "every" => lambda do |args| return EveryTrigger.new(args) end
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
        "send" => lambda do |args| return SendResponse.new(args) end,
        "reply" => lambda do |args| return ReplyResponse.new(args) end,
        "nick" => lambda do |args| return NickResponse.new(args) end,
        "set" => lambda do |args| return SetResponse.new(args) end,
        "breakif" => lambda do |args| return BreakResponse.new(args) end
    }

    @@advanced_responses = {
        "create" => lambda do |args| return CreateResponse.new(args) end,
        "log" => lambda do |args| return LogResponse.new(args) end,
        "list" => lambda do |args| return ListResponse.new(args) end,
        "save" => lambda do |args| return SaveResponse.new(args) end,
        "recover" => lambda do |args| return RecoverResponse.new(args) end
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
