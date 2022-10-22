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


static immutable Rectangle[4][2][2] allfloorRects = [
    [
        [
            Rectangle(0, 0, 150, 20),
            Rectangle(130, 0, 20, 150),
            Rectangle(0, 130, 150, 20),
            Rectangle(0, 0, 20, 150)
        ],
        [
            Rectangle(0, 0, 140, 20),
            Rectangle(130, 0, 20, 140),
            Rectangle(18, 130, 132, 20),
            Rectangle(0, 18, 20, 132)
        ]
    ],
    [
        [
            Rectangle(18, 0, 132, 20),
            Rectangle(130, 18, 20, 132),
            Rectangle(0, 130, 140, 20),
            Rectangle(0, 0, 20, 140)
        ],
        [
            Rectangle(18, 0, 122, 20),
            Rectangle(130, 18, 20, 122),
            Rectangle(18, 130, 122, 20),
            Rectangle(0, 18, 20, 122)
        ]
    ]
];

static Vector2[4] chestPos = [
    Vector2(59, 17),
    Vector2(101, 58),
    Vector2(61, 106),
    Vector2(12, 62)
];

Rectangle mkrect(Vector2 pos, float width, float height)
{
    return Rectangle(pos.x, pos.y, width, height);
}

Rectangle mkrect(Vector2 pos, Vector2 size)
{
    return Rectangle(pos.x, pos.y, size.x, size.y);
}

Rectangle mkrect(Texture2D t)
{
    return Rectangle(0, 0, t.width, t.height);
}

Rectangle flipY(Rectangle r)
{
    return Rectangle(r.x, r.y, r.width, -r.height);
}

struct AutoReleaser(T, alias releaseFunction)
{
    T item;
    alias item this;
    ~this() {
        releaseFunction(item);
    }
    @disable this(this);
}

auto loadTexture(const char *txtname)
{
    return AutoReleaser!(Texture2D, UnloadTexture)(LoadTexture(txtname));
}

struct SegmentedTexture
{
    Texture2D src;
    int cols;
    Vector2 frameSize;
    Vector2 center = Vector2(0, 0);

    void draw(Vector2 pos, int frame)
    {
        draw(mkrect(pos, frameSize), frame);
    }

    void draw(Rectangle dest, int frame)
    {
        auto frameOffset = Vector2(frameSize.x * (frame % cols), frameSize.y * (frame / cols));
        DrawTexturePro(src, mkrect(frameOffset, frameSize), dest, center, 0, Colors.WHITE);
    }

    void drawFlipX(Rectangle dest, int frame)
    {
        auto frameOffset = Vector2(frameSize.x * (frame % cols), frameSize.y * (frame / cols));
        auto srcrect = mkrect(frameOffset, frameSize.x * -1, frameSize.y);
        DrawTexturePro(src, srcrect, dest, center, 0, Colors.WHITE);
    }
}

void gameloop()
{
    InitWindow(5 * 150, 5 * 150, "Enter the Dungeon!");
    scope(exit) CloseWindow();

    auto room = loadTexture("assets/room.png");
    room.width = 150;
    room.height = 150;
    auto doors = loadTexture("assets/Doors.png");
    doors.width = 150;
    doors.height = 150;
    auto bossdoors = loadTexture("assets/BossDoors.png");
    bossdoors.width = 150;
    bossdoors.height = 150;
    auto allfloor = loadTexture("assets/allfloor.png");
    allfloor.width = 150;
    allfloor.height = 150;
    auto chest = loadTexture("assets/Chest.png");
    chest.width=45;
    chest.height=34;
    auto dungeonbat = loadTexture("assets/Dungeon Bat.png");
    dungeonbat.width = 100;
    dungeonbat.height = 200;
    auto cman = loadTexture("assets/dungeonMan.png");
    auto healingpotion = loadTexture("assets/healingpotion.png");
    auto branch = loadTexture("assets/branch.png");
    auto hearts = loadTexture("assets/hearts.png");

    RenderTexture2D inventoryTexture = LoadRenderTexture(GetScreenWidth() - 80, GetScreenHeight() - 200);
    scope(exit) UnloadRenderTexture(inventoryTexture);

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
    gs.user.health = 55;
    Room startingRoom;
    startingRoom.walls[Direction.west] = Wall.hallway;
    startingRoom.walls[Direction.north] = Wall.chest;
    startingRoom.outside[] = true;
    ++gs.nChests;
    ++gs.outerExits;
    //startingRoom.walls[] = Wall.chest;
    import dungeon.items;
    startingRoom.chestItems = [weapons[0], potions[0], potions[0], potions[0]];
    // add a bat and a dungeon crawler
    //gs.enemies ~= enemies[0];
    //gs.enemies[0].location = Loc(1, 1);
    gs.rooms[Loc(0, 0)] = startingRoom;

    // add some enemies

    gs.describeRoom;

    EventList events;
    events.initialize();
    events.repeat(100.msecs, {batFrame = !batFrame;});

    Vector2 mancenter = Vector2(38, 30);
    Vector2 chestcenter = Vector2(chest.width, chest.height) / 2;
    Vector2 offset = Vector2(0, 0);
    Vector2 heartOffset = Vector2(40, 33);
    Vector2 userpos = Vector2(0, 0);
    bool moving = false; // is the player moving.
    float walkSpeed = 1.5; // how fast does the player walk (in pixels/frame)
    bool inventoryDisplay = false;
    
    struct DebugState
    {
        Vector2 *targetVector;
        bool roomcenters = false;
        bool drawOuterWalls = false;
        bool showChestRatio = false;
    }

    DebugState dbg;

    void processDebugInput(const(char)[] input)
    {
        import std.range : split;
        import std.conv : to;
        auto words = input.split;
        if(words[1] == "off")
        {
            dbg = dbg.init;
            writeln("reset debug state");
        }
        else if(words[1].startsWith("ch"))
        {
            // move the appropriate chest
            dbg.targetVector = &chestPos[words[1][2 .. $].to!int];
            writeln("adjusting chest ", words[1][2 .. $]);
        }
        else if(words[1] == "mc")
        {
            dbg.targetVector = &mancenter;
            writeln("adjusting man center");
        }
        else if(words[1] == "ho")
        {
            dbg.targetVector = &heartOffset;
            writeln("adjusting heart offset");
        }
        else if(words[1] == "sh")
        {
            gs.user.health = words[2].to!int;
            writeln("set health to ", gs.user.health);
        }
        else if(words[1] == "cc")
        {
            dbg.targetVector = &chestcenter;
            writeln("adjusting chest center");
        }
        else if(words[1] == "src")
        {
            dbg.roomcenters = !dbg.roomcenters;
            writeln("toggle room centers to ", dbg.roomcenters);
        }
        else if(words[1] == "sow")
        {
            dbg.drawOuterWalls = !dbg.drawOuterWalls;
            writeln("toggle outer walls to ", dbg.drawOuterWalls);
        }
        else if(words[1] == "scr")
        {
            dbg.showChestRatio = !dbg.showChestRatio;
            writeln("toggle chest ratio display to ", dbg.showChestRatio);
        }
        else 
        {
            writeln("command not understood");
        }
    }

    void drawMan()
    {
        auto animation = SegmentedTexture(cman, 9, Vector2(40, 40), mancenter);
        auto dest = mkrect(Vector2(2.5 * 150, 2.5 * 150) + userpos, 75, 75);
        with(Direction) final switch(gs.user.dir)
        {
        case north:
            animation.draw(dest, walkframe + 3);
            break;
        case south:
            animation.draw(dest, walkframe);
            break;
        case east:
            animation.draw(dest, walkframe + 6);
            break;
        case west:
            animation.drawFlipX(dest, walkframe + 6);
            break;
        }
    }

    void drawHearts()
    {
        // each heart is 10 health
        auto h = gs.user.health;
        immutable hwidth = 20;
        immutable hheight = 20;
        immutable startx = GetScreenWidth - hwidth * 10 - 1;
        foreach(i; 0 .. 10)
        {
            auto imgv = h > 5 ? Vector2(0, 0) : h > 0 ? Vector2(100, 0) : Vector2(0, 100);
            auto rect = mkrect(imgv + heartOffset, hwidth, hheight);
            DrawTexturePro(hearts, rect, Rectangle(startx + i * hwidth, 1, hwidth, hheight), Vector2(0, 0), 0, Colors.WHITE);
            h -= 10;
        }
    }

    void buildInventoryTexture()
    {
        BeginTextureMode(inventoryTexture);
        ClearBackground(Colors.WHITE);
        foreach(idx, it; gs.user.inventory)
        {
            switch(it.name)
            {
            case "Branch":
                DrawTexture(branch, 1, cast(int)(10 + 32 * idx), Colors.WHITE);
                break;
            case "Healing Potion":
                DrawTexture(healingpotion, 1, cast(int)(10 + 32 * idx), Colors.WHITE);
                break;
            default:
                break;
            }
            DrawText(it.name.ptr, 33, cast(int)(12 + 32 * idx), 30, Colors.BLUE);
        }
        EndTextureMode();
    }

gameloop:
    while(!WindowShouldClose)
    {
        events.process();
        if(animateWalking && !moving && offset.x == 0 && offset.y == 0)
        {
            events.removeEvent(animateWalking);
            walkframe = 0;
            animateWalking = 0;
        }
        int kp = 0;
        if(dbg.targetVector !is null)
        {
            bool keypressed = false;
            if(IsKeyPressed(KeyboardKey.KEY_DOWN))
            {
                dbg.targetVector.y += 1;
                keypressed = true;
            }
            if(IsKeyPressed(KeyboardKey.KEY_UP))
            {
                dbg.targetVector.y -= 1;
                keypressed = true;
            }
            if(IsKeyPressed(KeyboardKey.KEY_LEFT))
            {
                dbg.targetVector.x -= 1;
                keypressed = true;
            }
            if(IsKeyPressed(KeyboardKey.KEY_RIGHT))
            {
                dbg.targetVector.x += 1;
                keypressed = true;
            }
            if(keypressed)
            {
                textbuf.setPin();
                writeln("target vector now ", *dbg.targetVector);
            }
        }
        else
        {
            auto motion = Vector2(0, 0);
            if(IsKeyDown(KeyboardKey.KEY_DOWN))
            {
                // move down
                motion.y += walkSpeed;
                gs.user.dir = Direction.south;
            }
            if(IsKeyDown(KeyboardKey.KEY_UP))
            {
                // move up
                motion.y -= walkSpeed;
                gs.user.dir = Direction.north;
            }
            if(IsKeyDown(KeyboardKey.KEY_LEFT))
            {
                // move left
                motion.x -= walkSpeed;
                gs.user.dir = Direction.west;
            }
            if(IsKeyDown(KeyboardKey.KEY_RIGHT))
            {
                // move right
                motion.x += walkSpeed;
                gs.user.dir = Direction.east;
            }
            // enable or disable the walking animation
            bool newmoving = motion != Vector2.init;
            if(newmoving && !moving)
            {
                animateWalking = events.repeat(75.msecs, {
                   walkframe = (walkframe + 1) % 3;
                });
                moving = true;
            }
            else if(!newmoving && moving)
            {
                events.removeEvent(animateWalking);
                moving = false;
            }
            userpos = userpos + motion;
            userpos.x = min(max(-55, userpos.x), 55);
            userpos.y = min(max(-55, userpos.y), 55);
        }
        if(IsKeyPressed(KeyboardKey.KEY_BACKSPACE))
            deleteCharacter();
        if(IsKeyPressed(KeyboardKey.KEY_ENTER))
        {
            textbuf.setPin();
            import std.conv : to;
            auto input = inputBuf[2 .. nChars];
            auto cmd = commands.getCommand(input);
            auto curpos = gs.user.location;
            inventoryDisplay = false;
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
            case "inventory":
                gs.showInventory();
                inventoryDisplay = true;
                buildInventoryTexture();
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
                userpos = Vector2(0, 0);
                offset = offsetStarts[gs.user.dir];
                events.removeEvent(animateWalking);
                events.removeEvent(movePlayer);
                animateWalking = events.repeat(75.msecs, {
                   walkframe = (walkframe + 1) % 3;
                });
                movePlayer = events.run(1.seconds, (double scale) {
                   import std.algorithm : min;
                   offset = offsetStarts[gs.user.dir] * (1.0 - min(1.0, scale));
                });
            }
            else
            {
                events.removeEvent(animateWalking);
                events.removeEvent(movePlayer);
                walkframe = 0;
                offset = Vector2(0, 0);
            }

            resetInput();
        }
        while((kp = GetCharPressed()) != 0)
        //while((kp = GetKeyPressed()) != 0)
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
                    DrawTextureV(room, Vector2(x * 150, y * 150) + offset, Colors.WHITE);
                    foreach(i; 0 .. 4)
                    {
                        if(r.walls[i] == Wall.door || r.walls[i] == Wall.hallway)
                        {
                            Rectangle rect = doorRects[i];
                            DrawTextureRec(doors, rect, Vector2(x * 150 + rect.x, y * 150 + rect.y) + offset, Colors.WHITE);
                        }
                        else if(r.walls[i] == Wall.boss)
                        {
                            Rectangle rect = doorRects[i];
                            DrawTextureRec(bossdoors, rect, Vector2(x * 150 + rect.x, y * 150 + rect.y) + offset, Colors.WHITE);
                        }
                        else if(r.walls[i] == Wall.open)
                        {
                            // draw extra floor. But only draw the part of the texture that is needed
                            bool lw = r.walls[left(i)] != Wall.open;
                            bool rw = r.walls[right(i)] != Wall.open;
                            Rectangle rect = allfloorRects[lw][rw][i];
                            DrawTextureRec(allfloor, rect, Vector2(x * 150 + rect.x, y * 150 + rect.y) + offset, Colors.WHITE);
                        }
                        else if(r.walls[i] == Wall.chest)
                        {
                            DrawTexturePro(chest, Rectangle(0, 0, chest.width, chest.height), mkrect(Vector2(x * 150, y * 150) + chestPos[i] + offset + chestcenter, chest.width, chest.height), chestcenter, 90 * i, Colors.WHITE);
                        }
                    }
                    if(dbg.roomcenters)
                        DrawCircleV(Vector2(x + 0.5, y + 0.5) * 150 + offset, 2, Colors.WHITE);
                }
            }

        // center room
        drawMan();
        if(dbg.roomcenters)
            DrawCircleV(Vector2(2.5, 2.5) * 150 + offset, 2, Colors.WHITE);
        //DrawRectangleLinesEx(Rectangle(2 * 150 - 5 + offset.x, 2 * 150 - 5 + offset.y, 160, 160), 5, Color(0x10, 0x10, 0x10, 0xff));
        if(dbg.drawOuterWalls)
        {
            static immutable corners = [
                Vector2(0, 0),
                Vector2(1, 0),
                Vector2(1, 1),
                Vector2(0, 1),
                Vector2(0, 0), // close the loop
            ];
            // draw all the outer walls
            foreach(x; 0 .. 5)
                foreach(y; 0 .. 5)
                {
                    auto roomLoc = gs.user.location;
                    roomLoc.col += x - 2;
                    roomLoc.row += y - 2;
                    if(auto r = roomLoc in gs.rooms)
                    {
                        foreach(i; 0 .. 4)
                        {
                            if(r.outside[i])
                            {
                                DrawLineV((Vector2(x, y) + corners[i]) * 150 + offset,
                                          (Vector2(x, y) + corners[i+1]) * 150 + offset,
                                          Colors.WHITE);
                            }
                        }
                    }
                }
        }
        if(dbg.showChestRatio)
        {
            DrawText(TextFormat("Num chests: %d, Num Rooms: %d, Ratio: %lf", cast(int)gs.nChests, cast(int)gs.rooms.length, cast(double)gs.nChests / gs.rooms.length), 1, 1, 20, Colors.WHITE);
        }

        // draw heart information
        drawHearts();
        if(inventoryDisplay)
        {
            // draw the inventory.
            DrawTextureRec(inventoryTexture.texture, inventoryTexture.texture.mkrect.flipY, Vector2(40, 40), Color(255, 255, 255, 0xc0));
        }
        renderText();
        renderInput();
        EndDrawing();
    }
}
