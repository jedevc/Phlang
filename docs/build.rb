def main()
    botname = "PhlangManual"

    pages = load_pages()

    summary = build_summary(pages.keys)
    help = build_help(botname)

    File.open("bots/metabot/#{botname}.phlang", 'w') do |file|
        file.write([pages.values.join("\n\n"), summary, help].join("\n\n"))
    end
end

def build_trigresp(name, data)
    return "msg \"^!phlang #{name}$\" reply \"#{data}\""
end

def load_pages()
    pages = {}
    Dir.glob("docs/*.txt") do |filename|
        File.open(filename, 'r') do |file|
            data = file.read()
            pagename = File.basename(filename, ".txt")
            pages[pagename] = build_trigresp("man #{pagename}", data)
        end
    end
    return pages
end

def build_summary(pagenames)
    msg = "Use '!phlang man PAGE' to access PAGE.\n"\
          "Available pages are: #{pagenames.join(', ')}"
    return build_trigresp("help", msg)
end

def build_help(botname)
    help = "For help on phlang use '!phlang help'."
    return "msg \"^!help @#{botname}$\" reply \"#{help}\""
end

if __FILE__ == $0
    main()
end
