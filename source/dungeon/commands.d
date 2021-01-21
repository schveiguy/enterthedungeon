module dungeon.commands;

struct Command
{
    bool singleLetter;
    string command;
    string description;
}

struct CommandProcessor
{
    Command[] commandList;
    string getCommand(const(char)[] input)
    {
        import std.algorithm : startsWith;
        if(input.startsWith("debug "))
            return "debug";
        string result;
        bool multiple;
        foreach(ref c; commandList)
        {
            if(input == c.command)
                return c.command;
            if(c.singleLetter && c.command[0 .. 1] == input)
                return c.command;
            if(c.command.startsWith(input))
            {
                if(result.length)
                    // multiple commands match
                    multiple = true;
                result = c.command;
            }
        }

        if(multiple)
            return null;
        return result;
    }

    void help()
    {
        import dungeon.textbuf;
        writeln("Here are the commands I understand:");
        foreach(ref c; commandList)
        {
            if(c.singleLetter)
                writefln("  `%s` or `%s`: %s", c.command, c.command[0], c.description);
            else
                writefln("  `%s`: %s", c.command, c.description);
        }
    }
}

CommandProcessor commands = CommandProcessor(
[
        Command(true, "north", "Look or move north"),
        Command(true, "south", "Look or move south"),
        Command(true, "west", "Look or move west"),
        Command(true, "east", "Look or move east"),
        Command(false, "open", "Open door or chest"),
        Command(false, "look", "Describe the current room, show the map"),
        Command(false, "help", "Show help"),
        Command(false, "quit", "Quit the game"),
        Command(false, "clear", "Clear the text output"),
]);
