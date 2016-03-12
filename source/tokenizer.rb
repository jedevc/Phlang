def Tokens(raw)
    tokens = []
    last = ""

    quotes = false
    comment = false

    raw.each_char do |c|
        if /\s/.match(c)
            if quotes or comment
                last += c
            else
                if last.length > 0
                    tokens.push(last)
                    last = ""
                end
            end
        elsif c == '#' and !quotes
            if !comment and last.length > 0
                tokens.push(last)
            end
            last = ""
            comment = !comment
        elsif c == '"' and !comment
            if last.length > 0 or quotes
                tokens.push(last)
                last = ""
            end
            quotes = !quotes
        else
            last += c
        end

        op = /([^\w\s.])$/.match(last)
        if op and !quotes and !comment
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
