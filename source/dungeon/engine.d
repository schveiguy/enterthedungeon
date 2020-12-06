module dungeon.engine;
import raylib;
import dungeon.textbuf;
import dungeon.state;
import dungeon.commands;

void gameloop()
{
    InitWindow(5 * 150, 5 * 150, "Enter the Dungeon!");

    auto room = LoadTexture("assets/room.png");
    room.width = 150;
    room.height = 150;
    auto dungeonbat = LoadTexture("assets/Dungeon Bat.png");
    dungeonbat.width = 100;
    dungeonbat.height = 200;

    inputBuf = "> \0".dup;
    nChars = 2;

    SetTargetFPS(30);

    Vector2 batPos = Vector2(300, 300);
    float[] xdelta = [2, 0, -2, 0];
    float[] ydelta = [0, 3, 0, -3];
    int framenum;
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

gameloop:
    while(!WindowShouldClose)
    {
        /*if(framenum % 100 == 0)
            writeln("hi: ", framenum);*/

        int kp = 0;
        if(IsKeyPressed(KeyboardKey.KEY_BACKSPACE))
            deleteCharacter();
        if(IsKeyPressed(KeyboardKey.KEY_ENTER))
        {
            import std.conv : to;
            auto input = inputBuf[2 .. nChars];
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
                break gameloop;
            case "help":
                commands.help();
                break;
            case "clear":
                textbuf.clear();
                break;
            default:
                writeln("I don't understand ", input);
                break;
            }

            resetInput();
        }
        while((kp = GetKeyPressed()) != 0)
        {
            if(kp < 0x80)
                addCharacter(cast(char)kp);
        }
        BeginDrawing();
        ClearBackground(Colors.WHITE);
        foreach(x; 0 .. 5)
            foreach(y; 0 .. 5)
                DrawTexture(room, x * 150, y * 150, Colors.WHITE);

        int offsety = ((++framenum / 3) & 1) * 100;
        DrawTextureRec(dungeonbat, Rectangle(0, offsety, 100, 100), batPos, Colors.WHITE);
        int dir = (framenum / 30) % 4;
        batPos.x += xdelta[dir];
        batPos.y += ydelta[dir];
            
        renderText();
        renderInput();
        EndDrawing();
    }

    CloseWindow();
}
