effects = effects or {}

effects["hair"] = {
    iLevel = 0.2,
    unique = false,
    onAttack = function(attacker, defender, wound)
        if wound.bleeding > 0 then
            
        end
    end
}

dfhack.onStatechange.weapon_effects=function(state)
    if state == SC_ON_WORLD_LOADED then
        effects = {}
    end
end