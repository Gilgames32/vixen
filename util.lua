function contains(tbl, x)
    for _, v in pairs(tbl) do
        if v == x then 
            return true
        end
    end
    return false
end

  ---@param sound Minecraft.soundID
function playerSound(sound)
    sounds:playSound(sound, player:getPos())
end