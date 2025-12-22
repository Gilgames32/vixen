require("scripts.tail")

local wagBind = keybinds:newKeybind("Wag", "key.keyboard.h")

wagBind:onPress(function()
    sounds:playSound("minecraft:entity.fox.ambient", player:getPos())
    force_start_anim(animations.model.wag)
    animations.model.tailWag:play()
end)

wagBind:onRelease(function ()
    animations.model.tailWag:stop()
end)
