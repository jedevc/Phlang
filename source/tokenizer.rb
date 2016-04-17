QUOTES = ["'", '"']
OPS = ['+', '-', '*', '/', '_', '=']

DIGIT = /\d/
IDENTICHAR = /[a-zA-Z$]/

class BaseToken
    def initialize()
    end
end
class VariadicToken < BaseToken
    attr_reader :lexeme
    def initialize(lexeme)
        @lexeme = lexeme
        super()
    end
end

class OpToken < VariadicToken
end
class LeftParenToken < BaseToken
end
class RightParenToken < BaseToken
end
class SeperatorToken < BaseToken
end
class EndToken < BaseToken
end
class EOFToken < BaseToken
end
class UnknownToken < BaseToken
end

class TriggerToken < VariadicToken
end
class ResponseToken < VariadicToken
end

class IdentifierToken < VariadicToken
end

class StringToken < VariadicToken
end
class NumberToken < VariadicToken
end

class Tokenizer
    attr_reader :last_token

    def initialize(raw, atriggers, aresponses)
        @raw = raw
        @atriggers = atriggers
        @aresponses = aresponses

        @position = 0
        @last_char = nil
        @last_token = nil

        next_char()
    end

    public
    def next_token()
        if @last_char.nil?
            @last_token = EOFToken.new()
        elsif /\s/ =~ @last_char
            next_char()
            next_token()
        elsif @last_char == '('
            @last_token = LeftParenToken.new
            next_char()
        elsif @last_char == ')'
            @last_token = RightParenToken.new
            next_char()
        elsif @last_char == ','
            @last_token = SeperatorToken.new
            next_char()
        elsif QUOTES.include? @last_char
            quotet = @last_char
            @last_token = StringToken.new(read_while {|c| c != quotet})
            next_char()
        elsif OPS.include? @last_char
            @last_token = OpToken.new(@last_char)
            next_char()
        elsif DIGIT =~ @last_char
            first = @last_char
            full = first + read_while {|c| /\d/ =~ c}
            @last_token = NumberToken.new(full.to_i)
        elsif IDENTICHAR =~ @last_char
            first = @last_char
            full = first + read_while {|c| /[a-zA-Z0-9]/ =~ c}
            if full == "end"
                @last_token = EndToken.new
            elsif @atriggers.include? full
                @last_token = TriggerToken.new(full)
            elsif @aresponses.include? full
                @last_token = ResponseToken.new(full)
            else
                @last_token = IdentifierToken.new(full)
            end
        else
            @last_token = UnknownToken.new
            next_char()
        end
        return @last_token
    end

    private
    def read_while(&blk)
        cs = ""
        loop do
            c = next_char()
            if c.nil?
                return cs
            elsif c == "\\"
                c = next_char()
                if c == 'n'
                    cs += "\n"
                else
                    cs += '\\' + c
                end
            else
                if blk.call(c, cs)
                    cs += c
                else
                    return cs
                end
            end
        end
    end

    def next_char()
        if @position < @raw.length
            comment = false
            loop do
                @last_char = @raw[@position]
                @position += 1

                if @last_char == '#'
                    comment = !comment
                    next
                end
                next if comment

                break
            end

            return @last_char
        else
            @last_char = nil
            return nil
        end
    end
end
