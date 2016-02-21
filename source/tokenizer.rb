def Tokens(raw, ops)
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

        ops.each do |op|
            if last.end_with?(op) and !quotes
                first = last.slice(0, last.length - op.length)
                if first.length > 0
                    tokens.push(first)
                end
                tokens.push(op)
                last = ""
            end
        end
    end
    if last.length > 0
        tokens.push(last)
    end
    return tokens
end
