local EZAnims = require("scripts.EZAnims")
local GSAnimBlend = require("scripts.GSAnimBlend")
local wheel = require("scripts.wheel")


local blendVanillaAnimHead = GSAnimBlend.callback.genBlendVanilla({
    models.model.root.Head,
})

local blendVanillaAnimArms = GSAnimBlend.callback.genBlendVanilla({
    models.model.root.LeftArm,
    models.model.root.RightArm,
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
    animations.model.fly
    :setBlendTime(2, 8)

    local quickDraw = {
        animations.model.bowL,
        animations.model.bowR,
        animations.model.blockL,
        animations.model.blockR,
    }
    for _, anim in pairs(quickDraw) do
        anim
        :setBlendTime(1, 8)
        :setBlendCurve("easeInOutSine")
    end

    animations.model.spearL:setPriority(1)
    animations.model.spearR:setPriority(1)
    animations.model.bowL:setPriority(1)
    animations.model.bowR:setPriority(1)
    animations.model.crossL:setPriority(1)
    animations.model.crossR:setPriority(1)
    animations.model.loadL:setPriority(1)
    animations.model.loadR:setPriority(1)
    animations.model.blockL:setPriority(1)
    animations.model.blockR:setPriority(1)

    animations.model.sprint:setPriority(2)
    animations.model.sprintjumpup:setPriority(2)
    animations.model.sprintjumpdown:setPriority(2)
    animations.model.climb:setPriority(2)

    animations.model.sprint:setSpeed(0.8)
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
    -- stop wheel anims when moving
    if wAnim and (wAnimPos - player:getPos()):lengthSquared() > wAnimStopDistanceSquared then pings.stopWheelAnim() end

    -- set walking animation speed
    if animations.model.walk:isPlaying() or animations.model.walkback:isPlaying() then
        local pVel = player:getVelocity()
        oldHVel = newHVel
        newHVel = math.lerp(oldHVel, pVel.xz:length(), 0.5)
        animations.model.walk:setSpeed(math.clamp(newHVel * 4, 0.5, 2))
        animations.model.walkback:setSpeed(math.clamp(newHVel * 6, 0.5, 2))
    else
        oldHVel = 0
        newHVel = 0
    end
    
    -- set climbing animation speed
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
        animations.model.walk:setBlend(math.min(1, math.abs(weight * 5)))
    end

    -- set calves rotation for swimming
    local lCalfRot = vec(0, 0, 0)
    local rCalfRot = vec(0, 0, 0)
    if animations.model.swim:isPlaying() then
        lCalfRot = vanilla_model.LEFT_LEG:getOriginRot()
        rCalfRot = vanilla_model.RIGHT_LEG:getOriginRot()
        lCalfRot.x = math.min(0, lCalfRot.x)
        rCalfRot.x = math.min(0, rCalfRot.x)
    end
    models.model.root.LeftLeg.LeftCalf:setRot(lCalfRot)
    models.model.root.RightLeg.RightCalf:setRot(rCalfRot)
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
    pings.setSkinSleeping(false)
    pings.playWheelAnim("wSit")
end)
