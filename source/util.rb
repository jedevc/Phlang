def to_number(ns)
    if ns.class == String
        if ns.include? '.'
            return ns.to_f
        else
            return ns.to_i
        end
    else
        return ns
    end
end
