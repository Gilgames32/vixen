local wheel = require("scripts.wheel")

local aurianims = require("scripts.aurianims")

local modelAnims = animations["model"]
local animController = aurianims.new()

animController:setDriver(function (data)
    local velocity = player:getVelocity()
    local sprinty = player:isSprinting()
    local pose = player:getPose()
    local inLiquid = #world.getBlockState(player:getPos()):getFluidTags() >= 1
    
    -- hands
    local handedness = player:isLeftHanded()
    local using = player:isUsingItem()
    local activeness = player:getActiveHand()
    
    local leftItem = player:getHeldItem(not handedness)
    local rightItem = player:getHeldItem(handedness)
    local rightActive = handedness and "OFF_HAND" or "MAIN_HAND"
    local leftActive = not handedness and "OFF_HAND" or "MAIN_HAND"

    data.leftItem = leftItem
    data.rightItem = rightItem
    data.leftActive = using and activeness == leftActive
    data.rightActive = using and activeness == rightActive
    data.leftActiveAction = data.leftActive and leftItem:getUseAction() or "NONE"
    data.rightActiveAction = data.rightActive and rightItem:getUseAction() or "NONE"

    data.isSleeping = pose == "SLEEPING"
    data.isSprinting = sprinty and not inLiquid
    

    data.velocity = velocity
    data.horizontalSpeed = velocity.xz:length()
    
    data.oldOnGround = data.onGround
    data.isOnGround = player:isOnGround()
    data.groundTime = data.isOnGround and data.groundTime + 1 or 0

    data.jumpTime = data.jumpTime * 0.85
    if not data.onGround and data.oldOnGround and velocity.y > 0.1 then
        data.jumpTime = math.min(velocity.y * 8, 2)
    elseif data.onGround then
        data.jumpTime = math.lerp(data.jumpTime, 0, 0.6)
    end
end,
{
    wheel = false,
    isSleeping = false,
    velocity = vec(0, 0, 0),
    horizontalSpeed = 0,
    isOnGround = true,
    groundTime = 0,
    jumpTime = 0,
}
)

local vanillaHandsAnim = aurianims.stack(
    aurianims.vanilla(
        models.model.root.LeftArm,
        models.model.root.RightArm
    ),
    modelAnims.handOverride -- override hand animations so that they dont play twice
)

local armsAnim = aurianims.stack(
    vanillaHandsAnim,
    aurianims.step(
        function (data)
            return not data.leftActive and not data.rightActive
        end,
        modelAnims.armsidle,
        aurianims.stack(
            -- left hand
            aurianims.switch(
                function (data)
                    return data.leftActiveAction
                end,
                {
                    NONE = nil,
                    BLOCK = modelAnims.blockL, -- shield
                    SPEAR = modelAnims.spearL, -- trident
                    CROSSBOW = modelAnims.crossbow, -- crossbow load
                }
            ),
            -- right hand
            aurianims.switch(
                function (data)
                    return data.rightActiveAction
                end,
                {
                    NONE = nil,
                    BLOCK = modelAnims.blockR, -- shield
                    SPEAR = modelAnims.spearR, -- trident
                    CROSSBOW = modelAnims.crossbow, -- crossbow load
                }
            ),
            -- bow
            aurianims.step(
                function (data)
                    local bowL = data.leftActive and data.leftActiveAction == "BOW"
                    local bowR = data.rightActive and data.rightActiveAction == "BOW"
                    return bowL or bowR
                end,
                modelAnims.bow,
                nil
            )
        )
    ),
    -- crossbow
    aurianims.step(
        function (data)
            local loadL = data.leftActive and data.leftActiveAction == "CROSSBOW"
            local loadR = data.rightActive and data.rightActiveAction == "CROSSBOW"
            local lTag = data.leftItem.tag
            local rTag = data.rightItem.tag
            local crossL = lTag and (lTag["Charged"] == 1 or (lTag["ChargedProjectiles"] and next(lTag["ChargedProjectiles"])~= nil)) or false
            local crossR = rTag and (rTag["Charged"] == 1 or (rTag["ChargedProjectiles"] and next(rTag["ChargedProjectiles"])~= nil)) or false
            return loadL or loadR or crossL or crossR
        end,
        modelAnims.crossbow,
        nil
    )
)

local walkAnim = aurianims.mix(
    function (data, old, anim1, anim2)
        anim2:speed(math.clamp(data.horizontalSpeed * 4, 0.5, 1.0))
        return math.lerp(
            old,
            math.clamp(data.horizontalSpeed * 4, 0, 1),
            0.4
        )
    end,
    aurianims.stack(
        modelAnims.tailidle,
        armsAnim
    ),
    modelAnims.walk
)

local movementAnim = aurianims.step(
    function (data)
        return data.isSprinting
    end,
    modelAnims.sprint,
    walkAnim
)

local playerAnim = aurianims.step(
    function (data)
        return data.isSleeping
    end,
    modelAnims.sleep,
    movementAnim
)

local mainAnim = aurianims.step(
    function (data)
        return data.wheel
    end,
    nil,
    playerAnim
)

animController:setTree(mainAnim)

function events.entity_init()
    animations.model.sprint:setSpeed(0.8)
end

local wheelAnim = nil
local wheelAnimPos = vec(0, 0, 0)
local wAnimStopDistanceSquared = 0.01

function events.tick()
    -- stop wheel anims when moving
    if wheelAnim and (wheelAnimPos - player:getPos()):lengthSquared() > wAnimStopDistanceSquared then pings.stopWheelAnim() end

    -- print(player:getHeldItem():getUseAction(), player:isUsingItem(), player:getActiveHand())
    -- printTable(animations:getPlaying())
end

function events.render(delta)
    -- if newHVel > 0 or oldHVel > 0 then
    --     local weight = math.lerp(oldHVel, newHVel, delta)
    --     animations.model.walk:setBlend(math.min(1, math.abs(weight * 5)))
    -- end

    -- -- set calves rotation for swimming
    -- local lCalfRot = vec(0, 0, 0)
    -- local rCalfRot = vec(0, 0, 0)
    -- if animations.model.swim:isPlaying() then
    --     lCalfRot = vanilla_model.LEFT_LEG:getOriginRot()
    --     rCalfRot = vanilla_model.RIGHT_LEG:getOriginRot()
    --     lCalfRot.x = math.min(0, lCalfRot.x)
    --     rCalfRot.x = math.min(0, rCalfRot.x)
    -- end
    -- models.model.root.LeftLeg.LeftCalf:setRot(lCalfRot)
    -- models.model.root.RightLeg.RightCalf:setRot(rCalfRot)
end


function pings.stopWheelAnim()
    if wheelAnim then
        wheelAnim:stop()
        wheelAnim = nil
    end
    animController.data.wheel = false
    pings.setSkinSleeping(false)
end
function pings.playWheelAnim(animName)
    wheelAnimPos = player:getPos()
    if wheelAnim then wheelAnim:stop() end
    wheelAnim = animations.model[animName]
    animController.data.wheel = true
    wheelAnim:play()
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
