require 'yaml/store'

class BotStore < YAML::Store
    def initialize(filename)
        super(filename)
        @thread_safe = true
    end
end
