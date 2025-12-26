local EZAnims = require("scripts.EZAnims")
local GSAnimBlend = require("scripts.GSAnimBlend")
local wheel = require("scripts.wheel")


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
    animations.model.walkjumpup
    :setBlendTime(2, 8)
    animations.model.walkjumpdown
    :setBlendTime(16, 4)
    :setBlendCurve("easeInOutSine")

    animations.model.sprint:setSpeed(0.8)
    animations.model.walkback:setSpeed(1.25)
end

local wAnim = nil
local wAnimPos = vec(0, 0, 0)
local wAnimStopDistanceSquared = 0.01
-- running animation speed and strength setting
local oldHVel = 0
local newHVel = 0
local oldVVel = 0
local newVVel = 0
function events.tick()
    if wAnim and (wAnimPos - player:getPos()):lengthSquared() > wAnimStopDistanceSquared then pings.stopWheelAnim() end

    if animations.model.walk:isPlaying() then
        local pVel = player:getVelocity()
        oldHVel = newHVel
        newHVel = math.lerp(oldHVel, pVel.xz:length(), 0.5)
        animations.model.walk:setSpeed(math.min(1.5, math.abs(newHVel / 0.275)))
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


function pings.stopWheelAnim()
    if wAnim then
        wAnim:stop()
        wAnim = nil
    end
    EZAnims.model:setAllOff(false)
    pings.setSkinSleeping(false)
end
function pings.playWheelAnim(animName)
    EZAnims.model:setAllOff(true)
    wAnimPos = player:getPos()
    if wAnim then wAnim:stop() end
    wAnim = animations.model[animName]
    wAnim:play(true)
end

wheel.animPage:newAction()
:setTitle("sleep")
:setItem("minecraft:red_bed")
:onLeftClick(function (_)
    pings.setSkinSleeping(true)
    pings.playWheelAnim("wSleep")
end)

wheel.animPage:newAction()
:setTitle("sit")
:setItem("minecraft:spruce_stairs")
:onLeftClick(function (_)
    pings.playWheelAnim("wSit")
end)
