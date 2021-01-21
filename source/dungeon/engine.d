module dungeon.engine;
import raylib;
import dungeon.textbuf;
import dungeon.state;
import dungeon.commands;
import dungeon.timer;
import core.time;
import std.math : PI_4;
import std.algorithm;

static immutable Rectangle[4] doorRects = [
    Rectangle(0, 0, 150, 45),
    Rectangle(105, 0, 45, 150),
    Rectangle(0, 105, 150, 45),
    Rectangle(0, 0, 45, 150)
];

static Vector2[4] chestPos = [
    Vector2(56, 16),
    Vector2(141, 55),
    Vector2(103, 140),
    Vector2(16, 100)
];

void gameloop()
{
    InitWindow(5 * 155, 5 * 155, "Enter the Dungeon!");
    scope(exit) CloseWindow();

    auto room = LoadTexture("assets/room.png");
    scope(exit) UnloadTexture(room);
    room.width = 150;
    room.height = 150;
    auto doors = LoadTexture("assets/Doors.png");
    scope(exit) UnloadTexture(doors);
    doors.width = 150;
    doors.height = 150;
    auto chest = LoadTexture("assets/Chest.png");
    scope(exit) UnloadTexture(chest);
    chest.width=45;
    chest.height=34;
    auto dungeonbat = LoadTexture("assets/Dungeon Bat.png");
    scope(exit) UnloadTexture(dungeonbat);
    dungeonbat.width = 100;
    dungeonbat.height = 200;
    auto cman = LoadTexture("assets/Dungeon Man.png");
    scope(exit) UnloadTexture(cman);

    inputBuf = "> \0".dup;
    nChars = 2;

    SetTargetFPS(60);

    Vector2 batPos = Vector2(310, 310);
    float[] xdelta = [1.5, 0, -1.5, 0];
    float[] ydelta = [0, 2.5, 0, -2.5];
    Vector2[] offsetStarts = [
        Vector2(0, -150),
        Vector2(150, 0),
        Vector2(0, 150),
        Vector2(-150, 0)
    ];
    int dir;
    int batFrame;
    int walkframe;
    size_t movePlayer;
    size_t animateWalking;
    GameState gs;
    Room startingRoom;
    startingRoom.walls[Direction.west] = Wall.door;
    startingRoom.walls[Direction.north] = Wall.chest;
    //startingRoom.walls[] = Wall.chest;
    import dungeon.items;
    startingRoom.chestItems = [weapons[0], potions[0], potions[0], potions[0]];
    // add a bat and a dungeon crawler
    gs.enemies ~= enemies[0];
    gs.enemies[0].location = Loc(1, 1);
    gs.rooms[Loc(0, 0)] = startingRoom;

    // add some enemies

    gs.describeRoom;

    EventList events;
    events.initialize();
    events.repeatEvery(100.msecs, {batFrame = !batFrame;});

    Vector2 *targetVector;
    Vector2 mancenter = Vector2(33, 48);
    Vector2 offset = Vector2(0, 0);
    
    bool roomcenters = false;

    void processDebugInput(const(char)[] input)
    {
        import std.range : split;
        import std.conv : to;
        auto words = input.split;
        if(words[1].startsWith("ch"))
        {
            // move the appropriate chest
            targetVector = &chestPos[words[1][2 .. $].to!int];
            writeln("adjusting chest ", words[1][2 .. $]);
        }
        else if(words[1] == "mc")
        {
            targetVector = &mancenter;
            writeln("adjusting man center");
        }
        else if(words[1] == "src")
        {
            roomcenters = !roomcenters;
            writeln("toggle room centers");
        }
        else 
        {
            writeln("command not understood");
        }
    }

    void drawMan()
    {
        Rectangle srcrect;
        with(Direction) final switch(gs.user.dir)
        {
        case north:
            srcrect = Rectangle(walkframe * 100, 100, 100, 100);
            break;
        case east:
            srcrect = Rectangle(walkframe * 100, 0, 100, 100);
            break;
        case west:
            srcrect = Rectangle(walkframe * 100, 0, -100, 100);
            break;
        case south:
            srcrect = Rectangle(walkframe * 100, 0, 100, 100);
            break;
        }
        DrawTexturePro(cman, srcrect, Rectangle(2.5 * 155, 2.5 * 155, 75, 75), mancenter, 0, Colors.WHITE);
    }

gameloop:
    while(!WindowShouldClose)
    {
        events.process();
        if(offset.x == 0 && offset.y == 0)
        {
            events.removeEvent(animateWalking);
            walkframe = 0;
        }
        int kp = 0;
        if(targetVector !is null)
        {
            bool keypressed = false;
            if(IsKeyPressed(KeyboardKey.KEY_DOWN))
            {
                targetVector.y += 1;
                keypressed = true;
            }
            if(IsKeyPressed(KeyboardKey.KEY_UP))
            {
                targetVector.y -= 1;
                keypressed = true;
            }
            if(IsKeyPressed(KeyboardKey.KEY_LEFT))
            {
                targetVector.x -= 1;
                keypressed = true;
            }
            if(IsKeyPressed(KeyboardKey.KEY_RIGHT))
            {
                targetVector.x += 1;
                keypressed = true;
            }
            if(keypressed)
                writeln("target vector now ", *targetVector);
        }
        if(IsKeyPressed(KeyboardKey.KEY_BACKSPACE))
            deleteCharacter();
        if(IsKeyPressed(KeyboardKey.KEY_ENTER))
        {
            import std.conv : to;
            auto input = inputBuf[2 .. nChars];
            auto cmd = commands.getCommand(input);
            auto curpos = gs.user.location;
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
                break gameloop;
            case "help":
                commands.help();
                break;
            case "clear":
                textbuf.clear();
                break;
            case "debug":
                processDebugInput(input);
                break;
            default:
                writeln("I don't understand ", input);
                break;
            }
            if(gs.user.location != curpos)
            {
                offset = offsetStarts[gs.user.dir];
                events.removeEvent(animateWalking);
                events.removeEvent(movePlayer);
                animateWalking = events.repeatEvery(75.msecs, (size_t evid) {
                   walkframe = (walkframe + 1) % 3;
                });
                movePlayer = events.runAfter(1.seconds, (double scale) {
                   import std.algorithm : min;
                   offset = Vector2Scale(offsetStarts[gs.user.dir], 1.0 - min(1.0, scale));
                });
            }

            resetInput();
        }
        while((kp = GetKeyPressed()) != 0)
        {
            if(kp < 0x80)
                addCharacter(cast(char)kp);
        }
        BeginDrawing();
        ClearBackground(Color(0x10, 0x10, 0x10, 0xff));
        //ClearBackground(Colors.BLACK);
        foreach(x; 0 .. 5)
            foreach(y; 0 .. 5)
            {
                auto roomLoc = gs.user.location;
                roomLoc.col += x - 2;
                roomLoc.row += y - 2;
                if(auto r = roomLoc in gs.rooms)
                {
                    DrawTextureV(room, Vector2Add(Vector2(x * 155, y * 155), offset), Colors.WHITE);
                    foreach(i; 0 .. 4)
                    {
                        if(r.walls[i] == Wall.door || r.walls[i] == Wall.hallway || r.walls[i] == Wall.open)
                        {
                            Rectangle rect = doorRects[i];
                            DrawTextureRec(doors, rect, Vector2Add(Vector2(x * 155 + rect.x, y * 155 + rect.y), offset), Colors.WHITE);
                        }
                        else if(r.walls[i] == Wall.chest)
                        {
                            DrawTextureEx(chest, Vector2(x * 155, y * 155).Vector2Add(chestPos[i]).Vector2Add(offset), 90 * i, 1, Colors.WHITE);
                        }
                    }
                    if(roomcenters)
                        DrawCircleV(Vector2((x + 0.5) * 155, (y + 0.5) * 155).Vector2Add(offset), 2, Colors.WHITE);
                }
            }

        // center room
        drawMan();
        if(roomcenters)
            DrawCircleV(Vector2(2.5 * 155, 2.5 * 155).Vector2Add(offset), 2, Colors.WHITE);
        DrawRectangleLinesEx(Rectangle(2 * 155 - 5 + offset.x, 2 * 155 - 5 + offset.y, 160, 160), 5, Color(0x10, 0x10, 0x10, 0xff));
        renderText();
        renderInput();
        EndDrawing();
    }
}
