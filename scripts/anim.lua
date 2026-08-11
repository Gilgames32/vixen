local wheel = require("scripts.wheel")

local aurianims = require("scripts.aurianims")

local modelAnims = animations["model"]
local animController = aurianims.new()

local sprintAnimSpeedMult = 0.8
local walkAnimSpeedMult = 0.9
local walkBackAnimSpeedMult = 1.4

animController:setDriver(function (data)
    local velocity = player:getVelocity()
    local bodyRot = player:getBodyYaw(1)
    local rotatedVelocity = vectors.rotateAroundAxis(bodyRot, player:getVelocity(), vec(0, 1, 0))
    local sprinty = player:isSprinting()
    local pose = player:getPose()
    local inLiquid = #world.getBlockState(player:getPos()):getFluidTags() >= 1
    local vehicle = player:getVehicle()
    local isCrouching = player:isCrouching()
    
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

    data.blockHeld = player:getHeldItem():isBlockItem()

    if vehicle ~= nil then pose = "SITTING" end
    data.pose = pose

    data.isSprinting = sprinty and not inLiquid
    data.sprintScale = math.lerp(data.sprintScale, data.isSprinting and 1 or 0, 0.6)

    data.velocity = velocity
    data.horizontalSpeed = velocity.xz:length()
    data.forwardSpeed = rotatedVelocity.z

    local speedMult = (isCrouching and 16 or 5)
    data.walkScale = math.clamp(data.horizontalSpeed * speedMult, 0, 1)
    data.smoothWalkScale = math.lerp(data.smoothWalkScale, data.walkScale, 0.5)
    data.smoothForwardScale = math.lerp(data.smoothForwardScale, math.clamp(data.forwardSpeed * speedMult, -1, 1), 0.5)
    
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
    groundTime = 0,
    jumpTime = 0,

    sprintTimer = 0,
    sprintScale = 0,
    smoothWalkScale = 0,
    smoothForwardScale = 0,
}
)

local vanillaHandsAnim = aurianims.stack{
    aurianims.vanilla{
        models.model.root.LeftArm,
        models.model.root.RightArm
    },
    modelAnims.handOverride -- override hand animations so that they dont play twice
}

local leftArmAnim = aurianims.switch(
    function (data)
        return data.leftActiveAction
    end,
    {
        NONE = nil,
        BLOCK = modelAnims.blockL, -- shield
        SPEAR = modelAnims.spearL, -- trident
    }
)

local rightArmAnim = aurianims.switch(
    function (data)
        return data.rightActiveAction
    end,
    {
        NONE = nil,
        BLOCK = modelAnims.blockR, -- shield
        SPEAR = modelAnims.spearR, -- trident
    }
)

local bowAnim = aurianims.conditional(
    function (data)
        local bowL = data.leftActive and data.leftActiveAction == "BOW"
        local bowR = data.rightActive and data.rightActiveAction == "BOW"
        return bowL or bowR
    end,
    modelAnims.bow
)

local crossbowAnim = aurianims.conditional(
    function (data)
        local loadL = data.leftActive and data.leftActiveAction == "CROSSBOW"
        local loadR = data.rightActive and data.rightActiveAction == "CROSSBOW"
        local lTag = data.leftItem.tag
        local rTag = data.rightItem.tag
        local crossL = lTag and (lTag["Charged"] == 1 or (lTag["ChargedProjectiles"] and next(lTag["ChargedProjectiles"])~= nil)) or false
        local crossR = rTag and (rTag["Charged"] == 1 or (rTag["ChargedProjectiles"] and next(rTag["ChargedProjectiles"])~= nil)) or false
        return loadL or loadR or crossL or crossR
    end,
    modelAnims.crossbow
)

local eatingAnim = aurianims.conditional(
    function (data)
        local eatL = data.leftActive and data.leftActiveAction == "EAT"
        local eatR = data.rightActive and data.rightActiveAction == "EAT"
        return eatL or eatR
    end,
    modelAnims.eat
)

local drinkingAnim = aurianims.conditional(
    function (data)
        local drinkL = data.leftActive and data.leftActiveAction == "DRINK"
        local drinkR = data.rightActive and data.rightActiveAction == "DRINK"
        return drinkL or drinkR
    end,
    modelAnims.drink
)

local walkBlockHoldAnim = aurianims.mix(
    function (data)
        return data.smoothWalkScale
    end,
    aurianims.step(
        function (data)
            return player:isLeftHanded()
        end,
        modelAnims.blockHoldL,
        modelAnims.blockHoldR
    ),
    modelAnims.blockHoldWalk
)

local rightArm = models.model.root.RightArm
local leftArm = models.model.root.LeftArm
local enderPivot = models.model.root.Body.EnderPivot
local blockHoldAnim = aurianims.step(
    function (data)
        -- set ender block wiggle
        local r = rightArm:getOffsetRot()
        local magic = math.rad(r.z - 2.9)
        local slow = math.sin(magic / 2)
        local fast = math.sin(magic * 2)
        enderPivot:setRot(vec(0, slow * 60 + 90, 0))
        enderPivot:setPos(vec(0, fast, -fast))
        
        return data.blockHeld
    end,
    walkBlockHoldAnim,
    aurianims.mix(
        function (data)
            return data.smoothWalkScale
        end,
        modelAnims.armsIdle,
        aurianims.mix(
            function (data)
                return data.smoothForwardScale / 2 + 0.5
            end,
            modelAnims.armsWalkBack,
            modelAnims.armsWalk
        )
    )
)

local armsAnim = aurianims.stack{
    aurianims.step(
        function (data)
            return data.leftActive or data.rightActive
        end,
        aurianims.stack{
            leftArmAnim,
            rightArmAnim,
            bowAnim,
        },
        aurianims.stack{
            blockHoldAnim,
            modelAnims.bigBlock,
        }
    ),
    crossbowAnim
}

local twoLeggedAnim = aurianims.stack{
    modelAnims.tailIdle,
    armsAnim,
    aurianims.mix(
        function (data)
            local speed = math.max(0.5, data.walkScale)
            modelAnims.walk:setSpeed(speed * walkAnimSpeedMult)
            modelAnims.armsWalk:setSpeed(speed * walkAnimSpeedMult)
            modelAnims.armsWalk:setTime(modelAnims.walk:getTime())
            modelAnims.walkBack:setSpeed(speed * walkBackAnimSpeedMult)
            modelAnims.armsWalkBack:setSpeed(speed * walkBackAnimSpeedMult)
            modelAnims.armsWalkBack:setTime(modelAnims.walkBack:getTime())
            return data.smoothWalkScale
        end,
        aurianims.blend(
            function (data)
                return 1 - (data.blockHeld and 0.75 or 0)
            end,
            vanillaHandsAnim
        ),
        aurianims.mix(
            function (data)
                return data.smoothForwardScale / 2 + 0.5
            end,
            modelAnims.walkBack,
            modelAnims.walk
        )
    )
}


local fourLeggedAnim = aurianims.stack{
    -- TODO
    modelAnims.sprint
}

local movementAnim = aurianims.mix(
    function (data)
        return data.sprintScale, false
    end,
    twoLeggedAnim,
    fourLeggedAnim
)

local crouchAnim = aurianims.mix(
    function (data)
        modelAnims.crouchWalk:setSpeed(data.smoothWalkScale * data.smoothForwardScale)
        return data.smoothWalkScale
    end,
    modelAnims.crouch,
    modelAnims.crouchWalk
)

local bendKneesToVanilla = aurianims.func(
    function (data, blend)
        -- set calves rotation to match the vanilla rotation of the legs making them look less stiff
        local lCalfRot = vec(0, 0, 0)
        local rCalfRot = vec(0, 0, 0)
        if blend > 0 then
            lCalfRot = vanilla_model.LEFT_LEG:getOriginRot()
            rCalfRot = vanilla_model.RIGHT_LEG:getOriginRot()
            lCalfRot.x = math.clamp(lCalfRot.x, -30, 0)
            rCalfRot.x = math.clamp(rCalfRot.x, -30, 0)
        end
        models.model.root.LeftLeg.LeftCalf:setRot(lCalfRot * blend)
        models.model.root.RightLeg.RightCalf:setRot(rCalfRot * blend)
    end
)

local playerAnim = aurianims.step(
    function (data)
        return data.pose == "SWIMMING" or data.pose == "FALL_FLYING" or data.pose == "SPIN_ATTACK"
    end,
    bendKneesToVanilla,
    aurianims.switch(
        function (data)
            return data.pose
        end, 
        {
            SLEEP = modelAnims.sleep,
            SITTING = modelAnims.sit,
            CROUCHING = crouchAnim,
            STANDING = aurianims.stack{
                movementAnim,
                eatingAnim,
                drinkingAnim,
            }
        }
    )
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
    animations.model.sprint:setSpeed(sprintAnimSpeedMult)
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

wheel.animPage:newAction()
:setTitle("sit alt")
:setItem("minecraft:oak_stairs")
:onLeftClick(function (_)
    pings.setSkinSleeping(false)
    pings.playWheelAnim("wSitAlt")
end)
