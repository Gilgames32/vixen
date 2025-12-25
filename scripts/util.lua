-- TODO: proper export

function contains(tbl, x)
    for _, v in pairs(tbl) do
        if v == x then 
            return true
        end
    end
    return false
end

  ---@param sound Minecraft.soundID
function pings.playerSound(sound)
    sounds:playSound(sound, player:getPos())
end

function force_start_anim(anim) 
    if anim:isPlaying() then
        anim:stop()
    end
    anim:play()
end