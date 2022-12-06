local function normal(stddev, mean)
    local exp_denom = 1/(2*stddev^2)
    local denom = 1/(math.sqrt(2*math.pi)*stddev)
    return function(x)
        return math.exp(-((x-mean)^2)*exp_denom)*denom
    end
end

local function pareto_distro(min, exponent)
    local exp_inv = 1/exponent
    return function(x)
        return min/(x^exp_inv)
    end
end

local pareto = pareto_distro(0.55, math.log(4,5))

artifactTypes = {}

local effects = dfhack.script_environment("entads/effects")

artifactTypes[df.item_type.WEAPON]=function(artifact, rng, iLevel)
    local weaponFile = dfhack.script_environment("entads/weapons")
    local weighted_tbl = {}
    local total_weight = 0
    local n = normal(0.2, iLevel)
    for _,v in ipairs(weaponEntadEffects) do
        if(v.unique) then
            local thisWeight = n(v.iLevel)
            total_weight = total_weight + thisWeight
            weighted_tbl[v] = thisWeight
        end
    end
    local weight = rng:drandom()*total_weight
    for effect,thisWeight in pairs(weighted_tbl) do
        weight = weight - thisWeight
        if weight <= 0 then
            return effect
        end
    end
end

function artifactRNG(artifact)
    local tbl = {artifact.id}
    for k,v in ipairs(artifact.name.words) do
        table.insert(tbl, v+1)
        table.insert(tbl,artifact.name.parts_of_speech[k])
    end
    table.insert(tbl, artifact.item:getType())
    table.insert(tbl, math.abs(artifact.item:getSubtype()))
    return dfhack.random.new(tbl)
end

function generate(artifact)
    local rng = artifactRNG(artifact)
    local item = artifact.item
    local options = {}
    local mat = dfhack.matinfo.decode(item.mat_type, item.mat_index)
    local is_edged = isEdged(item)
    local iLevel = pareto(1-rng:drandom())
    if iLevel < 1 then -- ~50%
        return
    else
        return artifactTypes[artifact.item:getType()](artifact, rng, iLevel)
    end
end

