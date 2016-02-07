class BaseExpression
    attr_reader :parent

    def initialize(parent)
        @parent = parent
        @children = []
    end

    public
    def add(c)
        @children.push(c)
    end

    def get()
        return []
    end
end

class SerialExpression < BaseExpression
    public
    def get()
        final = []
        @children.each do |c|
            if c.class == String
                final.push(c)
            else
                c.get().each do |i|
                    final.push(i)
                end
            end
        end
        return final
    end
end

class InlineExpression < BaseExpression
    public
    def get()
        final = []
        @children.each do |c|
            if c.class == String
                if final.length == 0
                    final.push(c)
                else
                    final[-1] += c
                end
            else
                f = c.get()
                if final.length == 0
                    final.push(f[0])
                else
                    final[-1] += f[0]
                end

                f.slice(1, f.length).each do |i|
                    final.push(i)
                end
            end
        end
        return final
    end
end

class RandomExpression < BaseExpression
    public
    def get()
        index = rand(@children.length)
        choice = @children[index]
        if choice.class == String
            return [choice]
        else
            return choice.get()
        end
    end
end

def botbot_expression(str)
    root = InlineExpression.new(nil)
    current = root
    phrase = ""
    (0...str.length).each do |i|
        if str[i-1] == '\\' && "[]{},".include?(str[i])
            phrase = phrase.slice(0, phrase.length-1) + str[i]
        elsif str[i] == '['
            if phrase.length > 0
                current.add(phrase)
                phrase = ""
            end
            n = SerialExpression.new(current)
            current.add(n)
            current = n
        elsif str[i] == '{'
            if phrase.length > 0
                current.add(phrase)
                phrase = ""
            end
            n = RandomExpression.new(current)
            current.add(n)
            current = n
        elsif str[i] == ']' || str[i] == '}'
            current.add(phrase.strip())
            phrase = ""

            current = current.parent
        elsif str[i] == ',' && current.parent != nil
            current.add(phrase.strip())
            phrase = ""
        else
            phrase = phrase + str[i]
        end
    end
    if phrase.length > 0
        current.add(phrase)
    end
    return root
end
