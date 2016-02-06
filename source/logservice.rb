require 'logger'

class LogService
    @@log = nil
    def self.provide(l)
        @@log = l
    end

    def self.get()
        @@log
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
