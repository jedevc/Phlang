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
    str.each_char do |c|
        if c == '['
            if phrase.length > 0
                current.add(phrase)
                phrase = ""
            end
            n = SerialExpression.new(current)
            current.add(n)
            current = n
        elsif c == '{'
            if phrase.length > 0
                current.add(phrase)
                phrase = ""
            end
            n = RandomExpression.new(current)
            current.add(n)
            current = n
        elsif c == ']' || c == '}'
            if phrase.length != 0
                current.add(phrase.strip())
                phrase = ""
            end
            current = current.parent
        elsif c == ',' && current.parent != nil
            if phrase.length != 0
                current.add(phrase.strip())
                phrase = ""
            end
        else
            phrase = phrase + c
        end
    end
    if phrase.length > 0
        current.add(phrase)
    end
    return root
end
