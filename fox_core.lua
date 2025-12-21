local yip_bind = keybinds:newKeybind("yip_bind", "key.keyboard.h")

local function force_start_anim(anim) 
    if anim:isPlaying() then
        anim:stop()
    end
    anim:play()
end

yip_bind:onPress(function()
    sounds:playSound("minecraft:entity.fox.ambient", player:getPos())
    -- force_start_anim(animations.model.ears_wag)
    force_start_anim(animations.model.tailWag)
end)
