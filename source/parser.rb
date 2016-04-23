require_relative 'tokenizer'

require_relative 'triggers'
require_relative 'responses'
require_relative 'nodes'

require_relative 'util'

class Parser
    def initialize(raw, atriggers=nil, aresponses=nil)
        @allowed_triggers = atriggers
        @allowed_responses = aresponses

        @tokens = Tokenizer.new(raw, Triggers.simple, Responses.simple + Responses.advanced)
        @tokens.next_token()
    end

    def parse
        blocks = []
        while !accept(EOFToken)
            blocks << block()
        end
        return RootNode.new(*blocks)
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
        raise "expected #{ttype} and got #{@tokens.last_token.class}"
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
                fn = FunctionNode.new(tok.lexeme, group())
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
                root = ApplyNode.new(root, num) {|c, n1, n2| to_number(n1.perform(c)) * to_number(n2.perform(c))}
            elsif accept(OpToken, '/')
                num = factor()
                root = ApplyNode.new(root, num) {|c, n1, n2| to_number(n1.perform(c)) / to_number(n2.perform(c))}
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
                root = ApplyNode.new(root, num) {|c, n1, n2| to_number(n1.perform(c)) + to_number(n2.perform(c))}
            elsif accept(OpToken, '-')
                num = term()
                root = ApplyNode.new(root, num) {|c, n1, n2| to_number(n1.perform(c)) - to_number(n2.perform(c))}
            elsif accept(OpToken, '_')
                num = term()
                root = ApplyNode.new(root, num) {|c, n1, n2| n1.perform(c).to_s + n2.perform(c).to_s}
            else
                return root
            end
        end
    end

    def group
        parts = []
        loop do
            if parts.length == 0 or accept(SeperatorToken)
                parts << expression()
            else
                break
            end
        end
        return MultiNode.new(*parts.compact)
    end

    def trigger
        trig = expect(TriggerToken).lexeme
        grp = group()

        return TriggerNode.new(trig, grp)
    end

    def response
        tok = @tokens.last_token
        if accept(IdentifierToken)
            expect(OpToken, '=')
            rest = expression()

            return SetResponseNode.new(tok.lexeme, rest)
        elsif accept(ResponseToken)
            if @allowed_responses.include? tok.lexeme
                grp = group()
                return ResponseNode.new(tok.lexeme, grp)
            else
                raise "no permissions to use #{tok.lexeme}"
            end
        end
    end

    def block
        trig = trigger()
        expect(EOLToken)
        loop do
            break if accept(EndToken)
            raise "expected EndToken before EOFToken" if accept(EOFToken)

            resp = response()
            expect(EOLToken)
            if resp.nil?
                raise "unexpected non-response token"
            else
                trig.attach(resp)
            end
        end
        expect(EOLToken)

        return MultiNode.new(trig)
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
