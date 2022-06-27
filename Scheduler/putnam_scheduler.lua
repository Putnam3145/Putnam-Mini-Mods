--[[
    This is a scheduler system that attempts to keep performance impact of
    repeatedly-running Lua scripts to a minimum by keeping track of the
    total time spent by them and suspending them if they're taking too long.
    As such, anything that must be consistent between systems and when
    reloading a save should not be put in here.
    Assume that all functions run by the scheduler will be
    either fully completed every tick or only go through
    one iteration each tick.
]]

local scheduledFuncs = {}

local function genCoroutineFunc(f)
    return function(run,time_not_to_overrun)
        while #run>0 do
            local status,err = pcall(f,table.remove(run))
            if not status then
                print(err)
            end
            if os.clock() > time_not_to_overrun then
                run, time_not_to_overrun = coroutine.yield(run)
            end
        end
        return run
    end
end

local scheduleParent = {
    run = function(this, time_not_to_overrun)
        if(not this.cor or coroutine.status(this.cor) == "dead") then
            this:startRun()
        end
        local ran
        ran,this.current_run = coroutine.resume(this.cor,this.current_run,time_not_to_overrun)
        return ran and #this.current_run > 0
    end,
    startRun = function(this)
        this.current_run = {}
        for _,v in ipairs(this.tbl) do
            table.insert(this.current_run,v)
        end
        this.cor = coroutine.create(genCoroutineFunc(this.current_run))
    end
}

local queue_head

local queue_tail

local remaining_priority = 0

local function enqueue(item)
    local node = queue_head
    while node and node.priority >= item.priority do
        node = node.queue_next
    end
    remaining_priority = remaining_priority + item.priority
    if not node then
        if queue_tail then
            queue_tail.queue_next = item
        else
            queue_head = item
        end
        queue_tail = item
    elseif node == queue_head then
        item.queue_next = node
        queue_head = item
    else
        item.queue_next = node.queue_next
        node.queue_next = item
    end
end

local function run_schedule()
    if not queue_head then
        for _,v in pairs(scheduledFuncs) do
            enqueue(v)
        end
    end
    local tick_length = math.max(0.001,1/df.global.enabler.fps)
    local end_time = os.clock() + tick_length
    while queue_head do

        local perc = queue_head.priority/remaining_priority
        perc = math.max(perc / 2, perc - queue_head.overrun)
        local allotted_length = perc*tick_length
        local time_not_to_overrun = os.clock() + allotted_length

        local before = os.clock()
        queue_head:run(time_not_to_overrun)
        local after = os.clock()

        queue_head.overrun = queue_head.overrun * 0.8 + ((after - before) - allotted_length) * 0.2
        remaining_priority = remaining_priority - queue_head.priority

        local next = queue_head.queue_next
        queue_head.queue_next = nil
        queue_head = next
        if after >= end_time then
            break
        end
    end
end

function add_to_schedule(tbl,f,priority) -- higher = more priority, used to be other way around
    local item = {
        func = f,
        priority = priority,
        tbl = tbl,
        overrun = 0,
        last_run_tick = df.global.world.cur_year_tick
    }
    setmetatable(item,{__index = scheduleParent})
    table.insert(scheduledFuncs, item)
    table.sort(scheduledFuncs, function(a,b) return a.priority < b.priority end)
end

function start_scheduler()
    require('repeat-util').scheduleEvery('Scheduler',1,'ticks',run_schedule)
end