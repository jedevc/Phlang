# Phlang docs

I've had a quite a strong past in botting with
[&xkcd](https://euphoria.io/room/xkcd). I created NotBot, managed a python API
for euphoria and helped with the development of BotBot. And I noticed that a lot
of tasks became fairly repetitive and boring. And that some things were actually
impossible. This annoyance caused me to create Phlang.

First off, Phlang is meant to be powerful. It's not meant to be nice and easy to
use or it's code to be particularly nice to read. I wanted to be able to create
not only simple regex based bots, but complex and powerful bots.

## Language

The Phlang language is fairly simple.

```
trigger args
response args
response args
end
```

A trigger is an object that listens for events. Then various responses
are attached that describe how the bot should respond. You can attach as many
responses as you like to a single trigger.

```
msg "!test"
reply "/me tests along."
end
```

Expressions are used in the args for triggers and responses for greater
flexibility. You can use basic mathematical operators (```+```, ```-```,
```*```, and ```/```), underscores (```_```) for string concentration and
parenthesis to control the order of operations. You can also use the ```%```
function to access the value of a variable.

```
msg "!dosum"
reply 1 + 4 / 2 # == 3 #
end
```

Use single or double quotes (```'```/```"```)to wrap string literals (sometimes
not actually required but always worth doing to prevent difficult to track down
bugs).

### Triggers

| Triggers                    | Description                                                              |
| :-------------------------- | :----------------------------------------------------------------------- |
| __start__                   | Triggers once when the bot is started.                                   |
| __msg__ _regex_             | Triggers when the bot receives a message matching _regex_.               |
| __receive__ _regex_         | Triggers when a bot receives an interbot broadcast matching _regex_.     |
| __timer__ _delay_ _regex_   | Triggers after waiting _delay_ seconds after a message matching _regex_. |
| __ptimer__ _delay_ _regex_  | Similar to __timer__ but multiple triggers are canceled.                 |
| __every__ _repeats_ _regex_ | Triggers after _repeats_ messages matching _regex_.                      |

Most of the triggers accept regexes. These regexes are ruby style regexes which
are carefully documented in the [Ruby Docs](http://ruby-doc.org/core/Regexp.html).

### Responses

Here are the basic responses that can be used with Phlang.

| Responses                    | Description                                              |
| :--------------------------- | :------------------------------------------------------- |
| __send__ _content_           | Send a root level message.                               |
| __reply__ _content_          | Send a reply to the message that triggered the response. |
| __broadcast__ _content_      | Broadcast an interbot message to all active bots.        |
| __nick__ _name_              | Set the bot's nick to _name_.                            |
| __set__ _name_ _value_       | Set variable _name_ to _value_.                          |
| __breakif__ _first_ _second_ | Break the execution of responses if _first_ == _second_  |

If you are hosting your bots locally, there are several more responses that you
can use that are disabled in the metabot version of Phlang for security reasons.

| Advanced responses       | Description                                       |
| :----------------------- | :------------------------------------------------ |
| __create__ _name_ _code_ | Create a Phlang bot called _name_ with _code_.    |
| __log__ _data_           | Log _data_ to the logfile.                        |
| __list__                 | List all the bots that are currently active.      |
| __save__ _snapname_      | Save a snapshot of all the currently active bots. |
| __recover__ _snapname_   | Load a snapshot of bots.                          |

There are also a set of variables and functions which can be used within
expressions for responses.

| Function       | Description                                        |
| :------------- | :------------------------------------------------- |
| ```$(Int)```   | Get the match group from the regex in the trigger. |
| ```?(*Args)``` | Pick an item randomly from the available args.     |

```
# Randomly select one of the two args #
msg "!rand ([\s\S]*) ([\s\S]*)"
reply ?($(1), $(2))
end
```

| Variable       | Description                                                  |
| :------------- | :----------------------------------------------------------- |
| ```time```     | Get the triggered time formatted as seconds since the epoch. |
| ```ftime```    | Get the triggered time formatted nicely.                     |
| ```sender```   | Get the name of the sender of the message.                   |
| ```senderid``` | Get the id of the sender of the message.                     |
| ```room```     | Get the current room name.                                   |

```
msg "!whoami"
reply "You are @" _ %(sender) _ " with an id of " _ %(senderid)
end
```

### Examples

A bot that repeats everything after an '!echo' command:
```
# EchoBot #
msg "^!echo ([\s\S]\*)$"
reply "You said: " _ $(1)
end
```

A bot that performs basic addition:
```
# AddBot #
msg "^!add (\d+) (\d+)$"
reply $(1) _ " + " _ $(2) _ " = " _ ($(1) + $(2))
end
```

A bot that rolls by after 10 minutes of inactivity:
```
# DemoWeed #
ptimer 600 "^([\s\S]*)$"
send "/me rolls by."
end
```

You can observe more examples of bots in ```bots/```.

## Hosting options

There are 2 options for running your bot.

### Using the metabot

To access the metabot, navigate to [&bots](euphoria.io/room/bots) and look for
the bot called PhlangBot (which is actually written in Phlang itself).

| Command                         | Result                                    |
| :------------------------------ | :---------------------------------------- |
| ```!phlang create @nick code``` | Creates a bot called _@nick_ with _code_. |
| ```!phlang list```              | List the bots currently running.          |
| ```!phlang save```              | Save a snapshot that can be loaded later. |
| ```!phlang recover [name]```    | Load a snapshot possibly with a name.     |

Bots created with the metabot have these commands that they are forced to reply
to.

| Command                         | Result                                    |
| :------------------------------ | :---------------------------------------- |
| ```!kill @bot```                | Kills _@bot_.                             |
| ```!pause @bot```               | Pauses _@bot_.                            |
| ```!restore @bot```             | Restores _@bot_.                          |
| ```!sendbot @bot &room```       | Send _@bot_ to _&room._                   |

Note that hosting your bot using PhlangBot has a few disadvantages. You cannot
access certain triggers and responses and there may be certain spam limits
enforced.

### Using locally

To host your bot locally, first make sure that Ruby and bundle are installed,
then simply run the following commands in bash.

```bash
# Clone the repo
git clone https://github.com/jedevc/Phlang.git

# Install required dependencies from the Gemfile
bundle install

# Run your bot
./run_phlang.sh -f path/to/your/bot -r roomname

# (Optional) Host the docs at localhost:8000
docs/run_docs.sh
```

```run_phlang.sh``` is a simple helper script for running Phlang. You can get
more information on it by using ```./run_phlang.sh -h```.

## Final remarks

Have fun using Phlang! If you have any comments or suggestions, please feel free
to contact me as caesar in [&xkcd](euphoria.io/room/xkcd).
