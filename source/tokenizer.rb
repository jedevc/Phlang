QUOTE_TYPES = ["'", '"']

class Tokens
    def initialize(raw)
        @tokens = []
        tokenize(raw)

        @readpt = -1
    end

    public
    def eat()
        if @readpt + 1 < @tokens.length
            @readpt += 1
            return @tokens[@readpt]
        else
            return nil
        end
    end

    def feed(token)
        @readpt -= 1
    end

    def done?
        return (@readpt + 1 >= @tokens.length)
    end

    private
    def tokenize(raw)
        @tokens = []
        last = ""

        quotes = nil
        comment = false

        raw.each_char do |c|
            if /\s/.match(c)
                if quotes or comment
                    last += c
                else
                    if last.length > 0
                        @tokens.push(last)
                        last = ""
                    end
                end
            elsif c == '#' and !quotes
                if !comment and last.length > 0
                    tokens.push(last)
                end
                last = ""
                comment = !comment
            elsif QUOTE_TYPES.include? c and (not quotes or quotes == c) and !comment
                if quotes
                    if last.length > 0 or quotes
                        @tokens.push(last)
                        last = ""
                    end
                    quotes = nil
                elsif !quotes
                    quotes = c
                end
            elsif last[-1] == '\\' and c == 'n'
                last = last.slice(0, last.length-1) + "\n"
            else
                last += c
            end

            op = /([^\w\s.])$/.match(last)
            if op and !quotes and !comment
                first = last.slice(0, last.length - op[1].length)
                if first.length > 0
                    @tokens.push(first)
                end
                @tokens.push(op[1])
                last = ""
            end
        end
        if last.length > 0
            @tokens.push(last)
        end
    end
end
