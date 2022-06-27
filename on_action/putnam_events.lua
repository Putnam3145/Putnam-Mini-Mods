-- A few events for modding.

--[[
    The eventTypes table describes what event types there are. Activation is done like so:
    enableEvent(eventTypes.ON_ACTION,1)
]]

onUnitAction=onUnitAction or dfhack.event.new()

local actions_already_checked=actions_already_checked or {}

things_to_do_every_action=things_to_do_every_action or {}

actions_to_be_ignored_forever=actions_to_be_ignored_forever or {}

local function checkForActions()
    for k,unit in ipairs(df.global.world.units.active) do
        local unit_id=unit.id
        actions_already_checked[unit_id]=actions_already_checked[unit_id] or {}
        local unit_action_checked=actions_already_checked[unit_id]
        for _,action in ipairs(unit.actions) do
            if action.type~=-1 then
                local action_id=action.id
                if not unit_action_checked[action_id] then
                    onUnitAction(unit_id,action)
                    unit_action_checked[action_id]=true
                end
            end
        end
    end
end

local df_date={}

df_date.__eq=function(date1,date2)
    return date1.year==date2.year and date1.year_tick==date2.year_tick
end

df_date.__lt=function(date1,date2)
    if date1.year<date2.year then return true end
    if date1.year>date2.year then return false end
    if date1.year==date2.year then
        return date1.year_tick<date2.year_tick
    end
end

df_date.__le=function(date1,date2)
    if date1.year<date2.year then return true end
    if date1.year>date2.year then return false end
    if date1.year==date2.year then
        return date1.year_tick<=date2.year_tick
    end
end

onEmotion=onEmotion or dfhack.event.new()

last_check_time=last_check_time or {year=df.global.cur_year,year_tick=df.global.cur_year_tick}

setmetatable(last_check_time,df_date)

local function checkEmotions()
    for k,unit in ipairs(df.global.world.units.active) do
        if unit.status.current_soul then
            for _,emotion in ipairs(unit.status.current_soul.personality.emotions) do
                local emotion_date={year=emotion.year,year_tick=emotion.year_tick}
                setmetatable(emotion_date,df_date)
                if emotion_date>=last_check_time then
                    onEmotion(unit,emotion)
                end
            end
        end
    end
    last_check_time.year=df.global.cur_year
    last_check_time.year_tick=df.global.cur_year_tick
end

eventTypes={
    ON_ACTION={name='onAction',func=checkForActions},
    ON_EMOTION={name='onEmotion',func=checkEmotions}
}

local events={}

function enableEvent(event,ticks)
    ticks=ticks or 1
    events[event]=ticks
    require('repeat-util').scheduleEvery(event.name,ticks,'ticks',event.func)
end

function disableEvent(event)
    events[event]=false
    require('repeat-util').cancel(event.name)
end

dfhack.onStateChange.putnamEvents=function(op)
    if op==SC_MAP_LOADED or op==SC_WORLD_LOADED then
        actions_to_be_ignored_forever={}
        for k,v in pairs(events) do
            if v then
                enableEvent(k,v)
            else
                disableEvent(k)
            end
        end
    end
end