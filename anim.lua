local EZAnims = require("EZAnims")
local GSAnimBlend = require("GSAnimBlend")

local blendVanillaAnimHeadless = GSAnimBlend.callback.genBlendVanilla({
    --models.model.root.Head, -- TODO
    models.model.root.Body,
    models.model.root.LeftArm,
    models.model.root.LeftLeg,
    models.model.root.RightArm,
    models.model.root.RightLeg,
})

function events.entity_init()

    animations.model.crouch
    :setBlendTime(0)

    animations.model.fall
    :blendTime(10, 1)
    :setBlendCurve("easeInOutSine")
    -- :onBlend(blendVanillaAnimHeadless)

    animations.model.sprint:setSpeed(0.8)

    -- animations.model.sprintjumpup
    -- :setBlendTime(2, 5)
    -- animations.model.sprintjumpdown
    -- :setBlendTime(10)

    -- animations.model.walk
    -- :onBlend(blendVanillaAnimHeadless)
    -- animations.model.sprint
    -- :onBlend(blendVanillaAnimHeadless)
end


-- running animation speed and strength setting
local oldVel = 0
local newVel = 0
function events.tick()
    if animations.model.walk:isPlaying() then
        oldVel = newVel
        newVel = math.lerp(oldVel, player:getVelocity().xz:length(), 0.5)
        animations.model.walk:setSpeed(math.min(1.5, math.abs(newVel / 0.3)))
    else
        oldVel = 0
        newVel = 0
    end
end
function events.render(delta)
    if newVel > 0 or oldVel > 0 then
        local weight = math.lerp(oldVel, newVel, delta)
        animations.model.walk:setBlend(math.min(1, math.abs(weight / 0.20)))
    end
end