local EZAnims = require("scripts.EZAnims")
local GSAnimBlend = require("scripts.GSAnimBlend")

local blendVanillaAnim = GSAnimBlend.callback.genBlendVanilla({
    models.model.root.Head,
    models.model.root.Body,
    models.model.root.LeftArm,
    models.model.root.LeftLeg,
    models.model.root.RightArm,
    models.model.root.RightLeg,
})

local blendVanillaAnimHead = GSAnimBlend.callback.genBlendVanilla({
    models.model.root.Head,
})

function events.entity_init()
    animations.model.crouchfall
    :setBlendTime(2)
    :setOnBlend(blendVanillaAnimHead)


    animations.model.jumpup
    :setBlendTime(2, 8)
    animations.model.jumpdown
    :setBlendTime(16, 4)
    :setBlendCurve("easeInOutSine")
    :setOnBlend(blendVanillaAnimHead)

    animations.model.sprint:setSpeed(0.8)
end


-- running animation speed and strength setting
local oldHVel = 0
local newHVel = 0
local oldVVel = 0
local newVVel = 0
function events.tick()
    if animations.model.walk:isPlaying() then
        local pVel = player:getVelocity()
        oldHVel = newHVel
        newHVel = math.lerp(oldHVel, pVel.xz:length(), 0.5)
        animations.model.walk:setSpeed(math.min(1.5, math.abs(newHVel / 0.32)))
    else
        oldHVel = 0
        newHVel = 0
    end
    
    if animations.model.climb:isPlaying() then
        local pVel = player:getVelocity()
        oldVVel = newVVel
        -- dont lerp when changing directions
        newVVel = (oldVVel * newVVel < 0) and pVel.y or math.lerp(oldVVel, pVel.y, 0.5) 
        animations.model.climb:setSpeed(math.min(1.5, (newVVel / 0.15)))
    else
        oldVVel = 0
        newVVel = 0
    end
end
function events.render(delta)
    if newHVel > 0 or oldHVel > 0 then
        local weight = math.lerp(oldHVel, newHVel, delta)
        animations.model.walk:setBlend(math.min(1, math.abs(weight / 0.20)))
    end
end