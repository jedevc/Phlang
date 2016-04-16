require_relative 'tokenizer'

require_relative 'triggers'
require_relative 'responses'

class ParseError < RuntimeError
end

class Parser
    def initialize(raw, atriggers=nil, aresponses=nil)
        @allowed_triggers = atriggers
        @allowed_responses = aresponses

        @tokens = Tokenizer.new(raw, Triggers.keys, Responses.keys)
        @tokens.next_token()
    end

    def parse
        return block()
    end

    private
    def accept(ttype, lex=nil)
        lt = @tokens.last_token
        if lt.is_a? ttype
            if lex.nil? or (lt.respond_to? "lexeme" and lt.lexeme == lex)
                @tokens.next_token()
                return lt
            end
        else
            return nil
        end
    end

    def expect(ttype, lex=nil)
        ret = accept(ttype, lex)
        return ret if ret
        raise "expected #{ttype} and got #{ret.class}"
    end

    def factor
        tok = @tokens.last_token
        if accept(NumberToken) or accept(StringToken)
            return RawNode.new(tok.lexeme)
        elsif accept(LeftParenToken)
            exp = expression()
            expect(RightParenToken)
            return exp
        elsif accept(IdentifierToken)
            if accept(LeftParenToken)
                fn = FunctionNode.new(tok.lexeme, expression())
                expect(RightParenToken)
                return fn
            else
                return VariableNode.new(tok.lexeme)
            end
        end
    end

    def term
        root = factor()
        loop do
            if accept(OpToken, '*')
                num = factor()
                root = ApplyNode.new(root, num) {|n1, n2, c| n1.perform(c) * n2.perform(c)}
            elsif accept(OpToken, '/')
                num = factor()
                root = ApplyNode.new(root, num) {|n1, n2, c| n1.perform(c) / n2.perform(c)}
            else
                return root
            end
        end
    end

    def expression
        root = term()
        loop do
            if accept(OpToken, '+')
                num = term()
                root = ApplyNode.new(root, num) {|n1, n2, c| n1.perform(c) + n2.perform(c)}
            elsif accept(OpToken, '-')
                num = term()
                root = ApplyNode.new(root, num) {|n1, n2, c| n1.perform(c) - n2.perform(c)}
            else
                return root
            end
        end
    end

    def group
        parts = [expression()]
        loop do
            if accept(SeperatorToken)
                parts << expression()
            else
                break
            end
        end
        return MultiNode.new(*parts)
    end

    def trigger
        trig = expect(TriggerToken).lexeme
        grp = group()

        return TriggerNode.new(trig, grp)
    end

    def response
        resp = expect(ResponseToken).lexeme
        grp = group()

        return ResponseNode.new(resp, grp)
    end

    def block
        trig = trigger()
        loop do
            break if accept(EndToken)
            trig.attach(response())
        end

        return ApplyNode.new(trig) {|t, c| t.perform(c)}
    end
end

class ExecutionContext
    attr_accessor :variables
    attr_accessor :functions

    attr_accessor :triggers

    def initialize()
        @variables = {}
        @functions = {}

        @triggers = []
    end
end

class Node
    def perform(context)
    end
end

class RawNode < Node
    def initialize(value)
        @value = value
    end

    def perform(context)
        return @value
    end
end

class VariableNode < Node
    def initialize(name)
        @name = name
    end

    def perform(context)
        return context.variables[@name]
    end
end

class FunctionNode < Node
    def initialize(name, *args)
        @name = name
        @args = args
    end

    def perform(context)
        return context.functions[@name].call(*@args.map{|a| a.perform(context)})
    end
end

class ApplyNode < Node
    def initialize(*values, &blk)
        @values = values
        @f = blk
    end

    def perform(context)
        return @f.call(*@values, context)
    end
end

class MultiNode < Node
    def initialize(*groups)
        @groups = groups
    end

    def perform(context)
        return @groups.map {|n| n.perform(context)}
    end
end

class TriggerNode < Node
    def initialize(name, exp)
        @name = name
        @expression = exp
        @resps = []
    end

    def attach(resp)
        @resps << resp
    end

    def perform(context)
        context.triggers << lambda do |bot|
            Triggers.trigger(@name, @expression.perform(context), bot) do |trigdata, message, room, bot|
                trigdata.rmatches.to_a.each_index do |i|
                    context.variables["$#{i}"] = trigdata.rmatches[i]
                end

                @resps.each do |r|
                    r.perform(context, message, room, bot)
                end

                trigdata.rmatches.to_a.each_index do |i|
                    context.variables.delete("$#{i}")
                end
            end
        end
    end
end

class ResponseNode < Node
    def initialize(name, exp)
        @name = name
        @expression = exp
    end

    def perform(context, message, room, bot)
        Responses.respond(@name, @expression.perform(context), message, room, bot)
    end
end
