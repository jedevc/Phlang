require 'logger'

class LogService
    @@log = nil

    def self.provide(l)
        @@log = l
    end
    
    def self.method_missing(m, *args, &blk)
        if @@log
            @@log.method(m).call(*args, &blk)
        end
    end
end

def create_log(threshold, out=STDOUT)
    log = Logger.new(out)
    log.formatter = lambda do |severity, datetime, progname, msg|
        datetime.utc()
        "[#{datetime}] #{severity}: #{msg}\n"
    end
    log.sev_threshold = threshold

    return log
end
