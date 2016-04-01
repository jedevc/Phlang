# Phlang

Phlang is a bot language for euphoria designed for creating advanced and complex
bots straight from [&bots](euphoria.io/room/bots) or from your own computer.

## Setup

If you're just interested in creating basic bots, then just go to
[&bots](euphoria.io/room/bots) for all your bot creating needs. If however, you
need a bit more control and access to the advanced triggers and responses, then
you can set it up like so (assuming you have Ruby and bundle installed):

```bash
# Clone the repo
git clone https://github.com/jedevc/Phlang.git

# Install required dependencies from the Gemfile
bundle install

# Run your bot
./phlang -f path/to/your/bot -r roomname

# (Optional) Host the docs at localhost:8000
docs/run_docs.sh
```

You can get more information on the options available by running
```./phlang --help```.

## Etymology

The name comes from a play on words with 'euphoria' and 'language' and is
supposed to be pronounced like
[this](https://translate.google.com/#en/es/phlang).
