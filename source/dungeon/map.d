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
        `+--o--+`,
        `|     |`,
        `o     o`,
        `|     |`,
        `+--o--+`,
    ],
    [
        `+-[_]-+`,
        `|     |`,
        ` ]   [`,
        `|  _  |`,
        `+-[ ]-+`,
    ],
    [
        `+-- --+`,
        `|     |`,
        `       `,
        `|     |`,
        `+-- --+`,
    ],
    [
        `+-----+`,
        `|  x  |`,
        `|x   x|`,
        `|  x  |`,
        `+-----+`,
    ],
];

void drawMap(ref GameState state)
{
    auto myloc = state.user.location;
    char[6 * 7 + 1][4 * 7 + 1] map = ' ';
    map[14][21] = '.';
    foreach(x; 0 .. 7)
        foreach(y; 0 .. 7)
        {
            auto roomx = x * 6;
            auto roomy = y * 4;
            auto roomloc = myloc;
            roomloc.col += x - 3;
            roomloc.row += y - 3;
            if(auto r = roomloc in state.rooms)
            {
                // north wall
                map[roomy][roomx .. roomx + 7] = images[r.walls[Direction.north]][0];
                map[roomy + 1][roomx .. roomx + 7] = images[r.walls[Direction.north]][1];
                // south wall
                map[roomy + 3][roomx .. roomx + 7] = images[r.walls[Direction.south]][3];
                map[roomy + 4][roomx .. roomx + 7] = images[r.walls[Direction.south]][4];
                // east wall
                map[roomy + 2][roomx + 5 .. roomx + 7] = images[r.walls[Direction.east]][2][5 .. 7];
                // west wall
                map[roomy + 2][roomx .. roomx + 2] = images[r.walls[Direction.west]][2][0 .. 2];
            }
        }
    foreach(ref x; map)
        writeln(x[]);
}

// Empty room
// +-----+
// |     |
// |  .  |
// |     |
// +-----+
//
// Doors on all walls
//
// +--o--+
// |     |
// o  .  o
// |     |
// +--o--+
//
// Hallways
// +-- --+
// |     |
//    .   
// |     |
// +-- --+
//
// Chests
// +-----+
// |  x  |
// |x . x|
// |  x  |
// +-----+
//
// Boss door
// +-[_]-+
// |     |
//  ] . [
// |  _  |
// +-[ ]-+
//
//
//
//
