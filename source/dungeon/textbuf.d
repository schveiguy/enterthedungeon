module dungeon.textbuf;
import raylib;
import std.array : Appender;

struct TextBuf
{
    enum maxLines = 5;
    enum maxLineLength = 100;
    char[][] lines;
    size_t last;

    Appender!(char[]) app;

    private void putLine(char[] ln)
    {
        if(lines.length < maxLines)
        {
            lines ~= ln;
            last = lines.length - 1;
        }
        else
        {
            last = (last + 1) % maxLines;
            lines[last] = ln;
        }
    }
    void addLines()
    {
        app.put('\0');
        auto addMe = app.data;
        while(addMe.length > maxLineLength + 1)
        {
            // find the last space that is before the max line length
            auto lastSpace = maxLineLength + 1;
            while(addMe[lastSpace] != ' ')
                --lastSpace;
            addMe[lastSpace] = 0;
            putLine(addMe[0 .. lastSpace + 1]);
            addMe = addMe[lastSpace + 1 .. $];
        }
        putLine(addMe);
        app = app.init;
    }

    void clear()
    {
        lines.length = 0;
        last = 0;
    }
}

TextBuf textbuf;

void writeln(T...)(T items)
{
    write(items);
    textbuf.addLines;
}

void writefln(T...)(string format, T items)
{
    writef(format, items);
    textbuf.addLines;
}
void writef(T...)(string format, T items)
{
    import std.format : formattedWrite;
    formattedWrite(textbuf.app, format, items);
}

void write(T...)(T items)
{
    import std.format : formattedWrite;
    static foreach(i; 0 .. T.length)
        formattedWrite(textbuf.app, "%s", items[i]);
}

enum fontSize = 13;
enum lineSize = fontSize + 4;
void renderText()
{
    int windowsize = 5 * 150;
    int rectheight = cast(int)(textbuf.lines.length + 2) * lineSize;
    DrawRectangle(0, windowsize - rectheight, windowsize, rectheight, Color(0, 0, 0, 0x40));
    foreach(i; 0 .. textbuf.lines.length)
    {
        auto lineToDraw = (textbuf.last + textbuf.lines.length - i) % textbuf.lines.length;
        DrawText(textbuf.lines[lineToDraw].ptr, 4, cast(int)(windowsize - lineSize - lineSize - 4 - i * lineSize), fontSize, Colors.GREEN);
    }
}

char[] inputBuf;
size_t nChars;

void renderInput()
{
    int windowsize = 5 * 150;
    DrawText(inputBuf.ptr, 4, windowsize - lineSize - 4, fontSize, Colors.ORANGE);
}

void addCharacter(char c)
{
    if(inputBuf.length == nChars + 1)
        inputBuf.length = inputBuf.length + 1;
    inputBuf[nChars++] = c;
    inputBuf[nChars] = 0;
}

void deleteCharacter()
{
    if(nChars > 2)
        inputBuf[--nChars] = 0;
}

void resetInput()
{
    nChars = 2;
    inputBuf[2] = 0;
}
