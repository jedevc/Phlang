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
        else
            last += c
        end
    end
    if last.length > 0
        tokens.push(last)
    end
    return tokens
end
