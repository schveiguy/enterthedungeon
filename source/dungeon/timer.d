module dungeon.timer;
import std.datetime.stopwatch;

enum isValidDG(T) = is(T : void delegate()) ||
    is(T : void delegate(size_t)) ||
    is(T : void delegate(double)) ||
    is(T : void delegate(double, size_t));

struct Event
{
    union {
        void delegate() dg1;
        void delegate(size_t) dg2;
        void delegate(double) dg3;
        void delegate(double, size_t) dg4;
    }
    Duration timeout; // 0 means destroy
    Duration repeat;
    Duration startTime;
    size_t id;
    this(DG)(DG dg, Duration timeout, Duration repeat, Duration startTime, size_t id)
        if (isValidDG!DG)
    {
        static if(is(DG : typeof(dg1)))
        {
            dg1 = dg;
            type = 0;
        }
        else static if(is(DG : typeof(dg2)))
        {
            dg2 = dg;
            type = 1;
        }
        else static if(is(DG : typeof(dg3)))
        {
            dg3 = dg;
            type = 2;
        }
        else static if(is(DG : typeof(dg4)))
        {
            dg4 = dg;
            type = 3;
        }
        else static assert(0, "Can't get here");
        this.timeout = timeout;
        this.repeat = repeat;
        this.startTime = startTime;
        this.id = id;
    }

    ubyte type;
    void process(Duration curTime) {
        switch(type)
        {
        case 0:
            dg1();
            break;
        case 1:
            dg2(id);
            break;
        case 2:
            dg3(cast(double)((curTime - startTime).total!"hnsecs") / (timeout - startTime).total!"hnsecs");
            break;
        case 3:
            dg4(cast(double)((curTime - startTime).total!"hnsecs") / (timeout - startTime).total!"hnsecs", id);
            break;
        default:
            break;
        }
    }
    bool isContinuous() {
        return (type & 0x02) >> 1;
    }
}

struct EventList
{
    StopWatch gameTimer;

    Event[] eventList;
    size_t nEvents;
    size_t evid;

    void initialize()
    {
        gameTimer.reset();
        gameTimer.start();
    }

    private void addEvent(Event e)
    {
        if(nEvents < eventList.length)
            eventList[nEvents++] = e;
        else
        {
            eventList ~= e;
            ++nEvents;
        }
    }
    size_t runAfter(DG)(Duration after, DG dg)
    {
        auto newEvent = Event(dg, gameTimer.peek + after, Duration.init, gameTimer.peek, ++evid);
        addEvent(newEvent);
        return newEvent.id;
    }

    size_t repeatEvery(DG)(Duration period, DG dg)
    {
        auto newEvent = Event(dg, gameTimer.peek + period, period, gameTimer.peek, ++evid);
        addEvent(newEvent);
        addEvent(newEvent);
        return newEvent.id;
    }

    void removeEvent(size_t id)
    {
        import std.algorithm : find;
        auto result = eventList[0 .. nEvents].find!((ref ev, size_t id) => ev.id == id)(id);
        if(result.length)
            result[0].id = 0;
    }

    void process()
    {
        if(nEvents == 0)
            return;
        // run through the list, processing any events that should fire. Then
        // clean up the list.
        auto curTime = gameTimer.peek;
        foreach(size_t i; 0 .. nEvents)
        {
            if(eventList[i].id && (eventList[i].isContinuous || curTime >= eventList[i].timeout))
            {
                eventList[i].process(curTime);
                if(curTime >= eventList[i].timeout)
                {
                    if(eventList[i].repeat > Duration.zero)
                    {
                        eventList[i].timeout += eventList[i].repeat;
                        eventList[i].startTime += eventList[i].repeat;
                    }
                    else
                        // remove from the list;
                        eventList[i].id = 0;
                }
            }
        }
        
        // now, remove any invalid events
        size_t validEvents = 0;
        foreach(size_t i; 0 .. nEvents)
        {
            if(eventList[i].id)
            {
                if(i != validEvents)
                    eventList[validEvents] = eventList[i];
                ++validEvents;
            }
        }
        nEvents = validEvents;
    }
}
