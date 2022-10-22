module dungeon.textbuf;
import raylib;
import std.array : Appender;

struct TextBuf
{
    enum idealLines = 5;
    enum maxLineLength = 100;
    char[][] lines;
    int pin; // line that can't scroll off

    Appender!(char[]) app;

    void setPin()
    {
        pin = cast(int)lines.length;
    }

    private void putLine(char[] ln)
    {
        normalize();
        lines ~= ln;
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

    void normalize()
    {
        // save the last idealLines as the first lines
        if(pin > 0 && lines.length > idealLines)
        {
            int i = cast(int)lines.length - idealLines;
            if(i > pin)
                i = pin;
            int j = 0;
            pin -= i;
            while(i < lines.length)
            {
                lines[j++] = lines[i++];
            }
            lines.length = j;
            lines.assumeSafeAppend;
        }
    }

    void clear()
    {
        lines.length = 0;
        lines.assumeSafeAppend;
        pin = 0;
    }

    int rectheight()
    {
        return cast(int)(lines.length + 2) * lineSize;
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

enum fontSize = 15;
enum lineSize = fontSize + 4;
void renderText()
{
    int windowsize = 5 * 150;
    int rectheight = textbuf.rectheight;
    DrawRectangle(0, windowsize - rectheight, windowsize, rectheight, Color(0, 0, 0, 0x40));
    foreach(i; 0 .. textbuf.lines.length)
    {
        auto lineToDraw = textbuf.lines.length - 1 - i;
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
