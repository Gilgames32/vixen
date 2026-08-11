---@param tbl table
---@param x any
---@return boolean
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

---@param anim Animation
function forceStartAnim(anim) 
    if anim:isPlaying() then
        anim:stop()
    end
    anim:play()
end

---@param key string
---@param default any
---@return any
function safeConfigLoad(key, default)
    local value = config:load(key)
    if value == nil then
        config:save(key, default)
        return default
    end
    return value
end
