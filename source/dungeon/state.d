module dungeon.state;
import dungeon.textbuf;

enum Direction
{
    north,
    east,
    south,
    west
}

Direction opposite(int dir)
{
    return cast(Direction)((dir + 2) % 4);
}

Direction left(int dir)
{
    return cast(Direction)((dir + 3) % 4);
}

Direction right(int dir)
{
    return cast(Direction)((dir + 1) % 4);
}

unittest {
    with(Direction)
    {
        assert(north.opposite == south);
        assert(north.left == west);
        assert(north.right == east);

        assert(east.opposite == west);
        assert(east.left == north);
        assert(east.right == south);

        assert(south.opposite == north);
        assert(south.left == east);
        assert(south.right == west);

        assert(west.opposite == east);
        assert(west.left == south);
        assert(west.right == north);
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

bool passable(Wall w)
{
    with(Wall)
        return w == door /*|| w == boss*/ || w == hallway || w == open;
}

enum CHEST_MAX_ITEMS = 8;

struct Room
{
    Wall[4] walls;
    bool[4] outside; // if the wall is an outside wall
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
    size_t outerExits = 0;
    double chestRatio = 5.0/100;
    size_t nChests = 0;

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
        user.dir = dir;

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
        with(Wall) final switch(room.walls[user.dir])
        {
        case solid:
            if(hasOpponent)
            {
                writefln("You desperately claw at the solid wall to the %s, but you can't escape the %s that way.", user.dir, opponent.name);
            }
            else
            {
                writefln("Alas, you do not have a blowtorch to open the solid wall to the %s.", user.dir);
            }
            break;
        case door:
            if(hasOpponent)
            {
                writefln("Before you have a chance to open the door, the %s jumps in front of you!", opponent.name);
            }
            else
            {
                writefln("You open the door to the %s and walk through...", user.dir);
                enterRoom(user.dir);
            }
            break;
        case boss:
            writefln("Open boss door TODO");
            break;
        case hallway:
            if(hasOpponent)
            {
                writefln("As you make a break towards the %s hallway, the %s taunts blocks your path, taunting you \"Where do you think you're going?!\"", user.dir, opponent.name);
            }
            else
            {
                writefln("You practice your best mime skills, pretending to open a door on the hallway to the %s...", user.dir);
                enterRoom(user.dir);
            }
            break;
        case chest:
            // open the chest, collect the inventory
            openChest();
            break;
        case open:
            if(hasOpponent)
            {
                writefln("As you make a break to the %s, the %s taunts blocks your path, taunting you \"Where do you think you're going?!\"", user.dir, opponent.name);
            }
            else
            {
                writefln("You practice your best mime skills, pretending to open a door on the open passage to the %s...", user.dir);
                enterRoom(user.dir);
            }
            break;
        }
    }

    // move to a (possibly not-yet-defined) room, given the direction
    void enterRoom(Direction dir)
    {
        auto curLoc = user.location;
        auto curRoom = curLoc in rooms;
        // determine if moving through a door
        curLoc = curLoc.nextRoom(dir);
        auto newRoom = curLoc in rooms;
        bool openingDoor = curRoom.walls[dir] == Wall.door;
        if(openingDoor)
        {
            curRoom.walls[dir] = Wall.hallway;
        }
        if(newRoom is null)
        {
            Room added;
            // random item on each wall.
            foreach(idx, ref w; added.walls)
            {
                import std.random;
                w = uniform!Wall;
                auto d = cast(Direction)idx;
                if(w == Wall.door)
                {
                    // for now change all doors to hallways
                    w = Wall.hallway;
                }
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
            bool chestPermitted = (cast(double)nChests / rooms.length) < chestRatio;
            foreach(ref w; added.walls)
            {
                if(w == Wall.chest)
                {
                    if(hasChest || !chestPermitted)
                        w = Wall.solid;
                    else
                        hasChest = true;
                }
            }
            rooms[curLoc] = added;
            if(hasChest)
                ++nChests;
            newRoom = curLoc in rooms;
            // resolve outer walls
            if(curRoom.outside[dir])
            {
                int numouters = 0;
                foreach(i; 0 .. 4)
                {
                    auto c = cast(Direction)i;
                    if(auto adj = curLoc.nextRoom(c) in rooms)
                    {
                        auto opp = c.opposite;
                        if(adj.outside[opp])
                        {
                            adj.outside[opp] = false;
                            if(adj.walls[opp].passable)
                                --outerExits;
                        }
                    }
                    else
                    {
                        ++numouters;
                        newRoom.outside[c] = true;
                        if(newRoom.walls[c].passable)
                            ++outerExits;
                    }
                }

                // if there are more than 1 outer walls on the new room, then
                // there is the potential that the new room is touching another
                // outer room. In that case, we need to trace the edges to see
                // if it's still an outer wall, and if not, turn all the outer
                // walls off there. If we then have no outer exits, we need to
                // make sure there is one in the new room.
                if(numouters > 1)
                {
                    auto checkLoc = curLoc.nextRoom(dir);
                    if(checkLoc in rooms || checkLoc.nextRoom(dir.left) in rooms || checkLoc.nextRoom(dir.right) in rooms)
                    {
                        int totaldoors = 0;
                        foreach(i; 0 .. 4)
                        {
                            if(newRoom.outside[i])
                                totaldoors += checkOuter(curLoc, cast(Direction)i);
                        }
                        if(totaldoors != outerExits)
                        {
                            import std.stdio : wln = writeln;
                            wln("Total doors detected: ", totaldoors, ", stored exits: ", outerExits);
                        }
                    }
                }

                // check to see if there are any outer exits, and if not, make
                // sure one exists.
                if(outerExits == 0)
                {
                    foreach(i; 0 .. 4)
                    {
                        if(newRoom.outside[i] && !newRoom.walls[i].passable)
                        {
                            // change the wall to a hallway
                            newRoom.walls[i] = Wall.hallway;
                            ++outerExits;
                            break;
                        }
                    }
                }

                assert(outerExits);
            }
            // TODO: fill up the chest.
        }
        else if(openingDoor)
        {
            newRoom.walls[dir.opposite] = Wall.hallway;
        }

        user.location = curLoc;

        // check to see if any enemies are here
        curEnemy = -1;
        foreach(i, ref e; enemies)
            if(e.location == curLoc)
                curEnemy = cast(int)i;

        describeRoom();
    }

    int checkOuter(Loc start, Direction wall)
    {
        // how many left turns. This will eventually be either 4 or -4.
        // If it's 4 left turns, then it's an inner wall, if it's 4 right
        // turns, then it's an outer wall.
        int nLefts = 0;
        foreach(i; 0 .. 2)
        {
            auto curl = start;
            auto curd = wall;
            int ndoors = 0;
            do
            {
                auto straight = curl.nextRoom(curd.right);
                auto diag = straight.nextRoom(curd);
                if(diag in rooms)
                {
                    curl = diag;
                    curd = curd.left;
                    ++nLefts;
                }
                else if(straight in rooms)
                {
                    curl = straight;
                }
                else
                {
                    curd = curd.right;
                    --nLefts;
                }
                if(i == 1)
                {
                    // now not an outer wall.
                    auto changeme = curl in rooms;
                    changeme.outside[curd] = false;
                    if(changeme.walls[curd].passable)
                        --outerExits;
                }
                else
                {
                    if(rooms[curl].walls[curd].passable)
                        ++ndoors;
                }
            } while(curl != start);

            if(i == 0 && nLefts != 4)
            {
                // still an outer wall, nothing needs to change.
                return(nLefts < 0 ? ndoors : 0);
            }
        }
        return 0;
    }

    void describeRoom()
    {
        //import dungeon.map;
        //drawMap(this);
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
                write("blue door with ornate carvings. ");
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

    void openChest()
    {
        auto room = user.location in rooms;
        write("You open the chest and find... ");
        if(room.chestItems.length == 0)
            writeln("nothing.");
        else
        {
            import std.algorithm : map;
            writefln("%-(a %s, %).", room.chestItems.map!(it => it.name));
            // add the items into the inventory.
            user.inventory ~= room.chestItems;
            room.chestItems = null;
        }
    }

    void showInventory()
    {
        if(user.inventory.length == 0)
            writeln("You don't have anything");
        else
        {
            import std.algorithm : map;
            writefln("You are carrying %-(a %s, %).", user.inventory.map!(it => it.name));
        }
    }
}
