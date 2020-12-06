import std.stdio;
import std.string;
import dungeon.state;
import dungeon.commands;
import dungeon.map;

void playGame(ref GameState gs)
{
    import std.conv : to;
    while(true)
    {
        writeln();
        write("> ");
        string input = readln().strip.toLower;
        auto cmd = commands.getCommand(input);
        switch(cmd)
        {
        case "north":
        case "east":
        case "west":
        case "south":
            gs.move(cmd.to!Direction);
            break;
        case "open":
            gs.open();
            break;
        case "look":
            gs.describeRoom();
            break;
        case "quit":
            writeln("Quitting!");
            return;
        case "help":
            commands.help();
            break;
        default:
            writeln("I don't understand ", input);
            break;
        }
    }
}

void main()
{
    import dungeon.engine;
    gameloop();
    /*while(true)
    {
        writeln("Welcome to the Dungeon. To play the game, type `play`. To play tutorial, type `tutorial`.");
        string answer = readln().strip.toLower;
        if(answer == "play")
        {
            GameState gs;
            Room startingRoom;
            startingRoom.walls[Direction.west] = Wall.door;
            startingRoom.walls[Direction.north] = Wall.chest;
            import dungeon.items;
            startingRoom.chestItems = [weapons[0], potions[0], potions[0], potions[0]];
            // add a bat and a dungeon crawler
            gs.enemies ~= enemies[0];
            gs.enemies[0].location = Loc(1, 1);
            gs.rooms[Loc(0, 0)] = startingRoom;

            // add some enemies

            gs.describeRoom;
            playGame(gs);
            return;
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
            writeln("  `look` = reexamine your surroundings");
            writeln("  `inv` = list inventory");
            writeln("  `examine` = examine shard holder");
            writeln("To use an item including a weapon or shield, type first 3 letters of the item");
            writeln("Any command can be abbreviated as long as it's a unique abbreviation. The only exceptions are the movement commands, which can always be abbreviated with one letter");
            writeln("Shards can be found in chests. If you find a boss door, you can use shards to open it.");
        }
        else
        {
            writeln("Invalid selection: ", answer, ", please type `play` or `tutorial`.");
        }
    }*/
}
