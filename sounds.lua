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
    
    if id:find("step") then return true end
    if soundLUT[id] ~= nil and soundLUT[id] ~= 0 then
        sounds:playSound(soundLUT[id], pos, vol, pitch, loop)
        return true
    end
end

-- snoring
local snoreingInterval = 40
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

