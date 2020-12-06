module dungeon.state;
import std.stdio;

enum Direction
{
    north,
    east,
    south,
    west
}

Direction opposite(Direction dir)
{
    with(Direction) final switch(dir)
    {
    case north:
        return south;
    case east:
        return west;
    case south:
        return north;
    case west:
        return east;
    }
}

enum Wall : ubyte
{
    solid,
    door,
    boss,
    hallway,
    chest,
    open,
}

enum CHEST_MAX_ITEMS = 8;

struct Room
{
    Wall[4] walls;
    Item[] chestItems;
}

struct Item
{
    string name;
    int health; // how much damage it does/healing it provides
    int magic; // how much magic power it has
    int protection; // how much defense it provides
    bool shard;
}

struct Loc
{
    int row;
    int col;
    Loc nextRoom(Direction dir)
    {
        with(Direction) final switch(dir)
        {
        case east:
            return Loc(row, col + 1);
        case west:
            return Loc(row, col - 1);
        case north:
            return Loc(row - 1, col);
        case south:
            return Loc(row + 1, col);
        }
    }
}


struct User
{
    int health;
    Item[] inventory;
    Direction dir;
    Loc location;
}

struct Enemy
{
    string name;
    int health;
    Item weapon;
    char icon;
    Loc location;
}

struct GameState
{
    Room[Loc] rooms;
    Enemy[] enemies;
    User user;
    int curEnemy = -1;
    Direction curDirection;

    ref Enemy opponent()
    {
        return enemies[curEnemy];
    }

    bool hasOpponent()
    {
        return curEnemy != -1;
    }

    void move(Direction dir)
    {
        Room *r = user.location in rooms;
        assert(r !is null);
        curDirection = dir;

        with(Wall) final switch(r.walls[dir])
        {
        case solid:
            if(hasOpponent)
            {
                writefln("You turn towards the %s wall, but there is no escape there!", dir);
            }
            else
            {
                writefln("You turn towards the %s wall, it is solid", dir);
            }
            break;
        case door:
            if(hasOpponent)
            {
                writefln("You turn towards the door on the %s, but the %s will not let you leave", dir, opponent.name);
            }
            else
            {
                writefln("You turn towards the door on the %s, nervous about what might be beyond", dir);
            }
            break;
        case boss:
            if(hasOpponent)
            {
                writefln("You turn towards the boss door on the %s, but maybe you should pay attention to your current foe", dir);
            }
            else
            {
                writefln("You turn towards the boss door on the %s, do you have a shard to unlock it?", dir);
            }
            break;
        case hallway:
            if(hasOpponent)
            {
                writefln("You flee down the %s hallway, but the %s drags you back!", dir, opponent.name);
            }
            else
            {
                writefln("Walking %s...", dir);
                enterRoom(dir);
            }
            break;
        case chest:
            if(hasOpponent)
            {
                writefln("You turn towards the chest on the %s wall, but you have better things to do than rummaging through it!", dir);
            }
            else
            {
                writefln("You turn towards the chest on the %s wall, eyes glinting with excitement", dir);
            }
            break;
        case open:
            if(hasOpponent)
            {
                writefln("You flee to the %s, but the %s drags you back!", dir, opponent.name);
            }
            else
            {
                writefln("Walking %s...", dir);
                enterRoom(dir);
            }
            break;
        }
    }

    void open()
    {
        auto room = user.location in rooms;
        with(Wall) final switch(room.walls[curDirection])
        {
        case solid:
            if(hasOpponent)
            {
                writefln("You desperately claw at the solid wall to the %s, but you can't escape the %s that way.", curDirection, opponent.name);
            }
            else
            {
                writefln("Alas, you do not have a blowtorch to open the solid wall to the %s.", curDirection);
            }
            break;
        case door:
            if(hasOpponent)
            {
                writefln("Before you have a chance to open the door, the %s jumps in front of you!", opponent.name);
            }
            else
            {
                writefln("You open the door to the %s and walk through...", curDirection);
                enterRoom(curDirection);
            }
            break;
        case boss:
            writefln("Open boss door TODO");
            break;
        case hallway:
            if(hasOpponent)
            {
                writefln("As you make a break towards the %s hallway, the %s taunts blocks your path, taunting you \"Where do you think you're going?!\"", curDirection, opponent.name);
            }
            else
            {
                writefln("You practice your best mime skills, pretending to open a door on the hallway to the %s...", curDirection);
                enterRoom(curDirection);
            }
            break;
        case chest:
            writeln("Open chest TODO");
            break;
        case open:
            if(hasOpponent)
            {
                writefln("As you make a break to the %s, the %s taunts blocks your path, taunting you \"Where do you think you're going?!\"", curDirection, opponent.name);
            }
            else
            {
                writefln("You practice your best mime skills, pretending to open a door on the open passage to the %s...", curDirection);
                enterRoom(curDirection);
            }
            break;
        }
    }

    // move to a (possibly not-yet-defined) room, given the direction
    void enterRoom(Direction dir)
    {
        auto curLoc = user.location;
        auto curRoom = curLoc in rooms;
        curLoc = curLoc.nextRoom(dir);
        auto newRoom = curLoc in rooms;
        if(newRoom is null)
        {
            Room added;
            // random item on each wall.
            foreach(idx, ref w; added.walls)
            {
                import std.random;
                w = uniform!Wall;
                auto d = cast(Direction)idx;
                // make sure the wall is consistent with any adjacent rooms.
                if(auto r2 = curLoc.nextRoom(d) in rooms)
                {
                    auto existingWall = r2.walls[d.opposite];
                    with(Wall) final switch(existingWall)
                    {
                    case chest:
                    case solid:
                        if(w == hallway || w == door || w == boss || w == open)
                            w = solid;
                        break;
                    case hallway:
                    case open:
                    case door:
                    case boss:
                        w = existingWall;
                        break;
                    }
                }
            }

            // make sure there is only at most one chest
            bool hasChest = false;
            foreach(ref w; added.walls)
            {
                if(w == Wall.chest)
                {
                    if(hasChest)
                        w = Wall.solid;
                    else
                        hasChest = true;
                }
            }
            rooms[curLoc] = added;
            newRoom = curLoc in rooms;
        }

        user.location = curLoc;

        // check to see if any enemies are here
        curEnemy = -1;
        foreach(i, ref e; enemies)
            if(e.location == curLoc)
                curEnemy = cast(int)i;

        describeRoom();
    }

    void describeRoom()
    {
        import dungeon.map;
        drawMap(this);
        write("You are in a room. ");
        auto room = user.location in rooms;
        foreach(i, w; room.walls)
        {
            if(w == Wall.solid)
                continue;
            writef("To the %s, there is a ", cast(Direction)i);
            with(Wall) final switch(w)
            {
            case solid:
                write("ERROR");
                break;
            case door:
                write("door. ");
                break;
            case boss:
                write("red door with ornate carvings. ");
                break;
            case hallway:
                write("hallway. ");
                break;
            case chest:
                write("wooden chest. ");
                break;
            case open:
                write("more room. ");
                break;
            }
        }
        if(curEnemy != -1)
        {
            writefln("There is a nasty looking %s here, eyeing you hungrily! ", opponent.name);
        }
        writeln();
    }
}
