require_relative 'triggers'
require_relative 'responses'

class PhlangBotConfig
    attr_reader :builtins

    attr_reader :allowed_triggers
    attr_reader :allowed_responses

    attr_reader :botinteraction

    def initialize(builtins, trigs, resps, botinteraction=false)
        @builtins = builtins
        @allowed_triggers = trigs
        @allowed_responses = resps
        @botinteraction = botinteraction
    end

    def to_h()
        return {
            "builtins" => @builtins.to_h,
            "allowed_triggers" => @allowed_triggers,
            "allowed_responses" => @allowed_responses,
            "botinteraction" => @botinteraction
        }
    end

    def self.from_h(h)
        return PhlangBotConfig.new(
            BuiltinConfig.from_h(h["builtins"]),
            h["allowed_triggers"],
            h["allowed_responses"],
            h["botinteraction"]
        )
    end
end

class BuiltinConfig
    attr_reader :admin
    attr_reader :util
    attr_reader :info

    def initialize(a, u, i)
        @admin, @util, @info = a, u, i
    end

    def to_h()
        return {
            "admin" => @admin,
            "util" => @util,
            "info" => @info
        }
    end

    def self.from_h(h)
        return BuiltinConfig.new(h["admin"], h["util"], h["info"])
    end
end

NO_BUILTINS = BuiltinConfig.new(false, false, false)
MINIMAL_BUILTINS = BuiltinConfig.new(false, false, true)
FULL_BUILTINS = BuiltinConfig.new(true, true, true)

MINIMAL_TRIGGERS = [
    "start",
    "msg",
    "timer",
    "ptimer"
]

FULL_TRIGGERS = MINIMAL_TRIGGERS

MINIMAL_RESPONSES = [
    "send",
    "reply",
    "nick",
    "set",
    "breakif"
]

FULL_RESPONSES = MINIMAL_RESPONSES + [
    "create",
    "log",
    "list",
    "save",
    "recover"
]
