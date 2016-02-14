def Tokens(raw)
    tokens = []
    current = ''
    quote_open = false
    raw.each_char do |c|
        if /\s/.match(c) && !quote_open
            if current.length > 0
                tokens.push(current)
            end
            current = ''
        elsif c == '"'
            quote_open = !quote_open
        else
            current += c
        end
    end
    if current.length > 0
        tokens.push(current)
    end
    return tokens
end
