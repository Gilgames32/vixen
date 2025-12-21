local wheel = require("wheel")

-- soundboard sounds
local soundboardEntries = {
    ambient = {
        icon = "minecraft:sweet_berries",
        sound = "minecraft:entity.fox.ambient",
    },
    bite = {
        icon = "minecraft:chicken",
        sound = "minecraft:entity.fox.bite",
    },
    eat = {
        icon = "minecraft:cooked_chicken",
        sound = "minecraft:entity.fox.eat",
    },
    aggro = {
        icon = "minecraft:pufferfish",
        sound = "minecraft:entity.fox.aggro",
    },
    screech = {
        icon = "minecraft:music_disc_11",
        sound = "minecraft:entity.fox.screech",
    },
    sniff = {
        icon = "minecraft:feather",
        sound = "minecraft:entity.fox.sniff",
    },
    spit = {
        icon = "minecraft:arrow",
        sound = "minecraft:entity.fox.spit",
    },
    -- hurt = {
    --     icon = "minecraft:heartbreak_pottery_sherd",
    --     sound = "minecraft:entity.fox.hurt",
    -- },
    sleep = {
        icon = "minecraft:red_bed",
        sound = "minecraft:entity.fox.sleep",
    },
}

-- replace player sfx with the vanilla fox sfx
local soundLUT = {
    ["minecraft:entity.player.hurt"] = "minecraft:entity.fox.hurt",
    ["minecraft:entity.generic.eat"] = "minecraft:entity.fox.eat",
    ["minecraft:entity.player.burp"] = "minecraft:entity.fox.bite",
}
function events.on_play_sound(id, pos, vol, pitch, loop, category)
    -- only replace sounds emitted by the player
    if not player:isLoaded() then return end
    if category ~= "PLAYERS" then return end
    if not ((pos - player:getPos()):length() < 0.1) then return end
    
    --if id:find("step") then return true end
    if soundLUT[id] ~= nil and soundLUT[id] ~= 0 then
        sounds:playSound(soundLUT[id], pos, vol, pitch, loop)
        return true
    end
end

-- snoring
local snoreingInterval = 60
local snoringTimer = 0
function events.tick()
    local isSleeping = player:getPose() == "SLEEPING"
    if not isSleeping then return end

    if snoringTimer < snoreingInterval then 
        snoringTimer = snoringTimer + 1
    else
        snoringTimer = 0
        sounds:playSound("minecraft:entity.fox.sleep", player:getPos())
    end
end


-- soundboard entries
for key, value in pairs(soundboardEntries) do
    wheel.soundboardPage:newAction()
    :setTitle(key)
    :setItem(value.icon)
    :onLeftClick(function (_)
        playerSound(value.sound)
    end)
end