effects = effects or {}

local sharpBits = 1|4|8|32|64

local PICK_STATUS_INCOMPATIBLE = 0

local PICK_STATUS_ALLOWED = 1

local PICK_STATUS_ALREADY_PICKED = 2

Effect = defclass(Effect)

Effect.ATTRS{
    iLevel = 0,
    unique = true,
    pickStatus = function(item)
        return PICK_STATUS_ALLOWED
    end,
    onAdd = function(item, iLevel, rng)
        return
    end,
    onAttack = function(item, iLevel, rng)
        return function(attacker,defender,wound)
            return
        end
    end,
    onAction = function(item, iLevel, rng)
        return function(unit, action)
            return
        end
    end
}

effects["sharp"] = Effect{
    iLevel = "leftover",
    unique = false,
    pickStatus=function(item)
        local s = item:getSharpness()
        if s == 0 then
            return PICK_STATUS_INCOMPATIBLE
        elseif s & sharpBits == sharpBits then
            return PICK_STATUS_ALREADY_PICKED
        else
            return PICK_STATUS_ALLOWED
        end
    end,
    onAdd = function(item, iLevel, rng)
        item:addSharpness(5000*iLevel^2)
        item.sharpness = item.sharpness | sharpBits
    end
}

effects["magic"] = Effect{
    iLevel = "leftover",
    unique = false,
    pickStatus=function(item)
        local m = item:getMagic()
        if m and #m > 0 then
            return PICK_STATUS_ALREADY_PICKED
        else
            return PICK_STATUS_ALLOWED
        end
    end,
    onAdd = function(item, iLevel, rng)
        item:addMagic(rng:random(9),math.floor((iLevel-1)*10),1)
    end
}

WeaponEffect = defclass(WeaponEffect, Effect)

WeaponEffect.ATTRS{
    
}

effects[df.item_type.WEAPON] = {

}