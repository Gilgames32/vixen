require("tail")
local wagBind = keybinds:newKeybind("Wag", "key.keyboard.h")

local function force_start_anim(anim) 
    if anim:isPlaying() then
        anim:stop()
    end
    anim:play()
end

wagBind:onPress(function()
    sounds:playSound("minecraft:entity.fox.ambient", player:getPos())
    force_start_anim(animations.model.wag)
    animations.model.tailWag:play()
end)

wagBind:onRelease(function ()
    animations.model.tailWag:stop()
end)
