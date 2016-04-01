require_relative 'tokenizer'

require_relative 'util'

COUNT_SEPERATOR = '#'

class RPN
    def initialize(tokens, *funcs)
        @tokens = tokens
        @funcs = funcs
    end

    public
    def calculate()
        stack = []
        @tokens.each do |t|
            if has_func?(t)
                f = get_func(t)

                vals = stack.pop(f.parameters.length)
                if vals.length == f.parameters.length
                    ret = f.call(*vals)
                    stack.push(ret)
                else
                    vals.each do |v|
                        stack.push(v)
                    end
                end
            elsif has_func?(t.split(COUNT_SEPERATOR)[0])
                name, args = t.split(COUNT_SEPERATOR)
                args = args.to_i
                vals = stack.pop(args)

                ret = get_func(name).call(*vals)
                stack.push(ret)
            else
                stack.push(t)
            end
        end
        return stack
    end

    private
    def get_func(func)
        @funcs.each do |funclist|
            if funclist.has_key? func
                return funclist[func]
            end
        end
        return nil
    end

    def has_func?(func)
        return get_func(func) != nil
    end
end

class ShuntContext
    attr_reader :operators
    attr_reader :functions

    attr_reader :left_paren
    attr_reader :right_paren
    attr_reader :separator

    def initialize(funcs={})
        basics = [
            ['*', lambda {|a, b| to_number(a) * to_number(b)}],
            ['/', lambda {|a, b| to_number(a) / to_number(b) if to_number(b) != 0}],
            ['+', lambda {|a, b| to_number(a) + to_number(b)}],
            ['-', lambda {|a, b| to_number(a) - to_number(b)}],
            ['_', lambda {|a, b| a.to_s + b.to_s}]
        ]
        @operators = basics.each_with_object({}) {|e, h| h[e[0]] = e[1]}
        @order = basics.map {|e| e[0]}

        @functions = funcs

        @left_paren, @right_paren = '(', ')'
        @separator = ','
    end

    def is_op?(op)
        return @operators.has_key?(op)
    end

    def is_func?(f)
        return @functions.has_key?(f)
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

class Expression < RPN
    def initialize(tokens, context)
        output = []
        stack = []

        argscounts = [0]

        tokens.each do |t|
            if /^[0-9]+$/.match(t)  # Number
                output.push(t)
            elsif context.is_func?(t)  # Function
                stack.push(t)
                argscounts.push(0)
            elsif t == context.separator  # Argument seperator
                while stack[-1] != context.left_paren
                    if stack.length == 0
                        raise RuntimeError, "Matching paren could not be found."
                    end
                    output.push(stack.pop())
                end
                argscounts[-1] += 1
            elsif context.is_op?(t)  # Operator
                while stack.length > 0 and context.is_op?(stack[-1]) and context.lower(t, stack[-1])
                    output.push(stack.pop())
                end
                stack.push(t)
            elsif t == context.left_paren  # Left parenthesis
                stack.push(t)
            elsif t == context.right_paren  # Right parenthesis
                while stack[-1] != context.left_paren
                    if stack.length == 0
                        raise RuntimeError, "matching left paren could not found"
                    end
                    output.push(stack.pop())
                end
                stack.pop()  # Get rid of matching paren

                if context.is_func?(stack[-1])
                    output.push(stack.pop() + "#{COUNT_SEPERATOR}#{argscounts[-1] + 1}")
                    argscounts.pop()
                end
            else  # Treat anything else as a string
                output.push(t)
            end
        end

        # Dump stack to output
        while stack.length > 0
            sym = stack.pop()
            if sym == context.left_paren
                raise RuntimeError, "matching right paren not found"
            end
            output.push(sym)
        end

        super(output, context.operators, context.functions)
    end
end
