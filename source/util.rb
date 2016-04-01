def to_number(ns)
    if ns.include? '.'
        return ns.to_f
    else
        return ns.to_i
    end
end
