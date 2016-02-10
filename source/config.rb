require_relative 'triggers'
require_relative 'responses'

class PhlangBotConfig
    attr_reader :builtins

    attr_reader :triggers
    attr_reader :responses

    def initialize(builtins, trigs, resps)
        @builtins = builtins
        @triggers = trigs
        @responses = resps
    end
end

class BuiltinConfig
    attr_reader :admin
    attr_reader :util
    attr_reader :info

    def initialize(a, u, i)
        @admin, @util, @info = a, u, i
    end
end

NO_BUILTINS = BuiltinConfig.new(false, false, false)
MINIMAL_BUILTINS = BuiltinConfig.new(false, false, true)
FULL_BUILTINS = BuiltinConfig.new(true, true, true)

MINIMAL_TRIGGERS = {
    "start" => lambda do |args| return StartTrigger.new(args) end,
    "msg" => lambda do |args| return MessageTrigger.new(args) end,
    "timer" => lambda do |args| return TimerTrigger.new(args) end,
    "ptimer" => lambda do |args| return PushTimerTrigger.new(args) end
}

FULL_TRIGGERS = MINIMAL_TRIGGERS

MINIMAL_RESPONSES = {
    "send" => lambda do |args| return SendResponse.new(args) end,
    "reply" => lambda do |args| return ReplyResponse.new(args) end,
    "nick" => lambda do |args| return NickResponse.new(args) end,
    "set" => lambda do |args| return SetResponse.new(args) end,
    "breakif" => lambda do |args| return BreakResponse.new(args) end
}

FULL_RESPONSES = MINIMAL_RESPONSES.merge({
    "create" => lambda do |args| return CreateResponse.new(args) end,
    "log" => lambda do |args| return LogResponse.new(args) end
})
