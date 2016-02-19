require_relative 'tokenizer'

class ShuntContext
    attr_reader :operators
    attr_reader :functions

    attr_reader :left_paren
    attr_reader :right_paren
    attr_reader :separator

    def initialize(funcs={})
        basics = [
            ['_', lambda {|a, b| a.to_s + b.to_s}]
        ]
        @operators = basics.each_with_object({}) {|e, h| h[e[0]] = e[1]}
        @order = basics.map {|e| e[0]}

        @functions = funcs

        @left_paren, @right_paren = '(', ')'
        @separator = ','
    end

    def lower(a, b)
        @order.reverse.each do |op|
            if op == a
                return true
            elsif op == b
                return false
            end
        end
        return false
    end
end

class RPN
    def initialize(tokens, funcs)
        @tokens = tokens
        @funcs = funcs
    end

    def calculate()
        puts @tokens.to_s
        stack = []
        @tokens.each do |t|
            if @funcs.has_key?(t)
                vals = stack.pop(@funcs[t].parameters.length)
                ret = @funcs[t].call(*vals)
                stack.push(ret)
            else
                stack.push(t)
            end
        end
        return stack
    end
end

class Expression < RPN
    def initialize(tokens, context)
        output = []
        stack = []

        tokens.each do |t|
            if /^[0-9]+$/.match(t)
                output.push(t)
            elsif context.functions.include?(t)
                stack.push(t)
            elsif t == context.separator
                while stack[-1] != context.left_paren
                    if stack.length == 0
                        raise RuntimeError, "Matching paren could not be found."
                    end
                    output.push(stack.pop())
                end
            elsif context.operators.include?(t)
                while stack.length > 0 and context.operators.include?(stack[-1]) and context.lower(t, stack[-1])
                    output.push(stack.pop())
                end
                stack.push(t)
            elsif t == context.left_paren
                stack.push(t)
            elsif t == context.right_paren
                while stack[-1] != context.left_paren
                    if stack.length == 0
                        raise RuntimeError, "Matching paren could not be found."
                    end
                    output.push(stack.pop())
                end
                stack.pop()

                if context.functions.include?(stack[-1])
                    output.push(stack.pop())
                end
            else
                output.push(t)
            end
        end
        while stack.length > 0
            output.push(stack.pop())
        end

        super(output, context.operators.merge(context.functions))
    end
end
