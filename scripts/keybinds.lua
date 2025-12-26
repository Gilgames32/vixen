require("scripts.tail")

local wagBind = keybinds:newKeybind("Hold to Wag", "key.keyboard.h")
wagBind:onPress(function() pings.wagOnPress() end)
wagBind:onRelease(function() pings.wagOnRelease() end)

function pings.wagOnPress()
    sounds:playSound("minecraft:entity.fox.ambient", player:getPos())
    force_start_anim(animations.model.wag)
    animations.model.tailWag:play()
    animations.model.tailWag:loop("LOOP")
end
function pings.wagOnRelease()
    animations.model.tailWag:loop("ONCE")
end