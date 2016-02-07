class PhlangBotConfig
    attr_reader :admin
    attr_reader :util
    attr_reader :info

    attr_reader :triggers
    attr_reader :responses

    def initialize(aui, trigs, resps)
        @admin, @util, @info = aui
        @triggers = trigs
        @responses = resps
    end
end

MINIMAL_CONFIG = PhlangBotConfig.new([false, false, false], TRIGGERS, RESPONSES + ADVANCED_RESPONSES)
NORMAL_CONFIG = PhlangBotConfig.new([false, false, true], TRIGGERS, RESPONSES + ADVANCED_RESPONSES)
ADMIN_CONFIG = PhlangBotConfig.new([true, true, true], TRIGGERS, RESPONSES)
