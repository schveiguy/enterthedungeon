import std.stdio;
import std.string;
import dungeon.state;

void playGame(ref GameState gs)
{
    import std.conv : to;
    while(true)
    {
        writeln();
        write("> ");
        string command = readln().strip.toLower;
        switch(command)
        {
        case "north":
        case "east":
        case "west":
        case "south":
            gs.move(command.to!Direction);
            break;
        case "open":
            gs.open();
            break;
        case "quit":
            writeln("Quitting!");
            return;
        default:
            writeln("I don't understand ", command);
            break;
        }
    }
}

void main()
{
    writeln("Welcome to the Dungeon. To play the game, type `play`. To play tutorial, type `tutorial`.");
    string answer = readln().strip.toLower;
    if(answer == "play")
    {
        GameState gs;
        Room startingRoom;
        startingRoom.walls[Direction.west] = Wall.door;
        startingRoom.walls[Direction.north] = Wall.chest;
        gs.rooms[Loc(0, 0)] = startingRoom;
        gs.describeRoom;
        playGame(gs);
    }
    else if(answer == "tutorial")
    {
        writeln("In this game, the goal is to walk through halls, and collect weapons and tools from chests. You fight enemies, collect shards to unlock new halls, and try to survive as long as possible.");
        writeln("Here are the commands you can use:");
        writeln("  `north` = move north");
        writeln("  `east` = move east");
        writeln("  `west` = move west");
        writeln("  `south` = move south");
        writeln("Note that a move command makes you face that direction");
        writeln("  `open` = open doors and chests (must be in front of you)");
        writeln("  `inv` = list inventory");
        writeln("  `map` = show map of known dungeon");
        writeln("  `examine` = examine shard holder");
        writeln("To use an item including a weapon or shield, type first 3 letters of the item");
        writeln("Any command can be abbreviated as long as it's a unique abbreviation. The only exceptions are the movement commands, which can always be abbreviated with one letter");
        writeln("Shards can be found in chests. If you find a boss door, you can use shards to open it.");
    }
    else
    {
        writeln("Invalid selection: ", answer, ", please type `play` or `tutorial`.");
    }
}
