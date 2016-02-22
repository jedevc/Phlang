def Tokens(raw)
    tokens = []
    last = ""
    quotes = false
    raw.each_char do |c|
        if /\s/.match(c)
            if quotes
                last += c
            else
                if last.length > 0
                    tokens.push(last)
                    last = ""
                end
            end
        elsif c == '"'
            quotes = !quotes
            if last.length > 0
                tokens.push(last)
                last = ""
            end
        else
            last += c
        end

        op = /([^\w\s.])$/.match(last)
        if op and !quotes
            first = last.slice(0, last.length - op[1].length)
            if first.length > 0
                tokens.push(first)
            end
            tokens.push(op[1])
            last = ""
        end
    end
    if last.length > 0
        tokens.push(last)
    end

    return tokens
end
