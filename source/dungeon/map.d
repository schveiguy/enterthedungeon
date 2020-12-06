module dungeon.map;
import dungeon.state;
import std.stdio;

immutable char[7][5][] images = [
    [
        `+-----+`,
        `|     |`,
        `|     |`,
        `|     |`,
        `+-----+`,
    ],
    [
        `+--v--+`,
        `|     |`,
        `)     (`,
        `|     |`,
        `+--^--+`,
    ],
    [
        `+-[_]-+`,
        `|     |`,
        ` ]   [ `,
        `|  _  |`,
        `+-[ ]-+`,
    ],
    [
        `+-| |-+`,
        `|     |`,
        `_     _`,
        `|     |`,
        `+-| |-+`,
    ],
    [
        `+-----+`,
        `|  x  |`,
        `|x   x|`,
        `|  x  |`,
        `+-----+`,
    ],
    [
        `+     +`,
        `       `,
        `       `,
        `       `,
        `+     +`,
    ],
];

ubyte[][4] masks =
[
    [
        0b1111111,
        0b0111110,
        0b0000000,
        0b0000000,
        0b0000000,
    ],
    [
        0b1000000,
        0b1100000,
        0b1100000,
        0b1100000,
        0b1000000,
    ],
    [
        0b0000000,
        0b0000000,
        0b0000000,
        0b0111110,
        0b1111111,
    ],
    [
        0b0000001,
        0b0000011,
        0b0000011,
        0b0000011,
        0b0000001,
    ],
];


void drawMap(ref GameState state)
{
    auto myloc = state.user.location;
    char[7 * 7 + 1][5 * 7 + 1] map = ' ';
    map[17][24] = '.';
    if(state.hasOpponent)
        map[17][23] = state.opponent.icon;
    void blitImage(ref const char[7][5] image, int dir, int xpos, int ypos)
    {
        foreach(row; 0 .. 5)
            foreach(col; 0 .. 7)
                if(masks[dir][row] & (1 << col))
                    map[ypos + row][xpos + col] = image[row][col];
    }
    foreach(x; 0 .. 7)
        foreach(y; 0 .. 7)
        {
            auto roomx = x * 7;
            auto roomy = y * 5;
            auto roomloc = myloc;
            roomloc.col += x - 3;
            roomloc.row += y - 3;
            if(auto r = roomloc in state.rooms)
            {
                foreach(i; 0 .. 4)
                    blitImage(images[r.walls[i]], i, roomx, roomy);
            }
        }
    foreach(ref x; map)
        writeln(x[]);
}
