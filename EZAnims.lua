-- V3.0.0 for 0.1.0 and above
-- Made by JimmyHelp

local anims = {}

local controller = {}
local controllerMT = {__index = controller}

local objects = {}

local exList = {
    "idle",
    "walk",
    "walkback",
    "jumpup",
    "jumpdown",
    "walkjumpup",
    "walkjumpdown",
    "fall",
    "crouchfall",
    "sprint",
    "sprintjumpup",
    "sprintjumpdown",
    "crouch",
    "crouchwalk",
    "crouchwalkback",
    "crouchjumpup",
    "crouchjumpdown",
    "elytra",
    "elytradown",
    "trident",
    "sleep",
    "swim",
    "sit",
    "sitmove",
    "sitmoveback",
    "sitjumpup",
    "sitjumpdown",
    "sitpass",
    "crawl",
    "crawlstill",
    "fly",
    "flywalk",
    "flywalkback",
    "flysprint",
    "flyup",
    "flydown",
    "climb",
    "climbstill",
    "climbdown",
    "climbcrouch",
    "climbcrouchwalk",
    "water",
    "waterwalk",
    "waterwalkback",
    "waterup",
    "waterdown",
    "watercrouch",
    "watercrouchwalk",
    "watercrouchwalkback",
    "watercrouchup",
    "watercrouchdown",
    "hurt",
    "death"
}

local incList = {
    "attackR",
    "attackL",
    "mineR",
    "mineL",
    "holdR",
    "holdL",
    "eatR",
    "eatL",
    "drinkR",
    "drinkL",
    "blockR",
    "blockL",
    "bowR",
    "bowL",
    "loadR",
    "loadL",
    "crossR",
    "crossL",
    "spearR",
    "spearL",
    "spyglassR",
    "spyglassL",
    "hornR",
    "hornL",
    "brushR",
    "brushL",
}

local GSAnimBlend
for _, key in ipairs(listFiles(nil,true)) do
    if key:find("GSAnimBlend$") then
        GSAnimBlend = require(key)
        break
    end
end
if GSAnimBlend then GSAnimBlend.safe = false end

local function setBlends(ex,inc,o,init)
    for _,list in pairs(o.aList) do
        for _,value in pairs(list.list) do
            if (GSAnimBlend.animData[value] and GSAnimBlend.animData[value]["EZAnims$hasBlendTime"]) and init then goto CONTINUE end
            value:setBlendTime(list.type == "excluAnims" and ex or inc)
           ::CONTINUE::
        end
    end
end

---@param ex? number
---@param inc? number
function controller:setBlendTimes(ex,inc)
    if not GSAnimBlend then error("GSAnimBlend was not found in the avatar, and this function is for interacting with GSAnimBlend.",2) end
    if type(ex) ~= "number" and ex ~= nil then
        error("The first arg is a non-number value ("..type(ex).."), must be a number or nil.",2)
    end
    if type(inc) ~= "number" and inc ~= nil then
        error("The second arg is a non-number value ("..type(inc).."), must be a number or nil.",2)
    end
    if ex == nil then
        ex = 0
    end
    if inc == nil then
        inc = ex
    end
    setBlends(ex,inc,self)
    return self
end

local function getSeg(name)
    local words = {}
    for word in name:gmatch("[^_]+") do
        words[#words+1] = word
    end
    return words
end

local flyinit
local function addAnims(bb,o)
    local listy = o.aList
    for _,anim in pairs(bb) do
        for name,animation in pairs(anim) do
            local words = getSeg(name)
            if not flyinit then
                if words[1]:find("fly") then
                    flyinit = true
                end
            end
            for key, _ in pairs(o.aList) do
                if words[1]:match("^"..key.."[0-9]*$") then
                    listy[key].list[#listy[key].list+1] = animation
                end
            end
        end
    end

    if GSAnimBlend then setBlends(4,4,o,true) end
end

---@param anim table
---@param ifFly? boolean
function controller:setAnims(anim,ifFly)
    flyinit = ifFly
    for key, value in pairs(anim) do
        self.aList[key].list = value
    end
    if GSAnimBlend then setBlends(4,4,self,true) end
    return self
end

local fallVel = -0.6
---@param vel? number
function anims:setFallVel(vel)
    if type(vel) ~= "number" and vel ~= nil then
        error("Tried to set the velocity to a non-number value ("..type(vel)..").")
    end
    fallVel = vel or -0.6
    return self
end

local oneJump = false
---@param state? boolean
function anims:setOneJump(state)
    oneJump = state or false
    return self
end

local auto = true
function anims:disableAutoSearch()
    auto = false
    return self
end

---@param anim string
---@param toggle boolean
function controller:setRestart(anim,toggle)
    self.aList[anim].restart = not toggle
    return self
end

local function getPlay(anim)
    local exists, hold = pcall(anim.isHolding,anim)
    return anim:isPlaying() or (exists and hold)
end

local function getOverriders(type,o)
    return o.overrideStates[type] or o.overrideStates.allAnims
end

local function addOverriders(self,type,...)
    for _, value in pairs({...}) do
        if #self.overriders[type] == 64 then
            error("The max amount of overriding animations for "..type.." (64) was reached. Do not put the code for adding overriding animations in a function, it will infinitely add animations.",3)
        end
        self.overriders[type][#self.overriders[type]+1] = value
    end
end

---@param state? boolean
function controller:setAllOff(state)
    self.setOverrides.allAnims = state
    return self
end

---@param state? boolean
function controller:setExcluOff(state)
    self.setOverrides.excluAnims = state
    return self
end

---@param state? boolean
function controller:setIncluOff(state)
    self.setOverrides.incluAnims = state
    return self
end

---@param ... Animation
function controller:addExcluOverrider(...)
    addOverriders(self,"excluAnims",...)
    return self
end

---@param ... Animation
function controller:addIncluOverrider(...)
    addOverriders(self,"incluAnims",...)
    return self
end

---@param ... Animation
function controller:addAllOverrider(...)
    addOverriders(self,"allAnims",...)
    return self
end

---@param exState? string
---@param inState? string
function controller:setState(exState,inState)
    if type(exState) ~= "string" and exState ~= nil then
        error("The first arg is a non-string value ("..type(exState).."), must be a string or nil.",2)
    end
    if type(inState) ~= "string" and inState ~= nil then
        error("The second arg is a non-string value ("..type(inState).."), must be a string or nil.",2)
    end
    self.toggleState = {excluAnims = exState or "",incluAnims = inState or exState or ""}
    return self
end

function controller:getState()
    return self.toggleState
end

local function getStates(type,o)
    return o.toggleState[type]
end

---@param spec? string
function controller:getAnimationStates(spec)
    if type(spec) ~= "string" and spec ~= nil then
        error("The animation state is a non-string value ("..type(spec).."), must be a string or nil.",2)
    end
    if spec then 
        return self.aList[spec].active 
    else 
        local states = {}
        for k,v in pairs(self.aList) do
            states[k] = v.active
        end
        return states
    end
end

local function setAnimation(anim,override,state,o)
    local saved = o.aList[anim]
    local exists = true
    local words = {}
    for _,value in pairs(saved.list) do
        if getSeg(value:getName())[2] == state then
            exists = false
        end
    end
    for _, value in pairs(saved.list) do
        words = getSeg(value:getName())
        if not words[2] then words[2] = not exists and "" or state end
        if words[2] == "outro" then words[3] = "outro" words[2] = "" end
        if words[1]:match("^"..anim.."[0-9]*$") then
            if words[3] == "outro" then
                if words[2] == state then -- outro anims
                    value:setPlaying(not saved.active and not override)
                else
                    value:stop()
                end
            else
                if words[2] == state then -- not outro anims
                    if not saved.active and saved.stop then break end
                    if saved.active and saved.stop and not override then
                        if not saved.restart then value:restart() else value:play() end
                    end
                    value:setPlaying(saved.active and not override)
                else
                    value:stop()
                end
            end
        else
            value:stop()
        end
    end
end

if events.damage then -- 0.1.5 check
    function events.damage()
        for _,o in pairs(objects) do
            local hurting = o.aList.hurt
            hurting.active = true
            setAnimation("hurt",getOverriders(hurting.type,o),getStates(hurting.type,o),o)
        end
    end
end

local flying = false
function pings.EZAnims_cFly(x)
    flying = x
end

function anims:isFlying()
    return flying
end

local jumpTracker = false
function anims:isJumping()
    return jumpTracker
end

local diff = false
local rightResult, leftResult, targetEntity, rightMine, leftMine, rightAttack, leftAttack, oldhitBlock, targetBlock, blockSuccess, blockResult, hitBlock
local yvel, grounded, oldgrounded, hasJumped, cFlying, oldcFlying
local cooldown = false
local updateTimer, oldhp = 0,0
local toggleDiff
local timer = 10
local function getInfo()
    if host:isHost() then
        if flyinit then
            cFlying = host:isFlying()
            if cFlying ~= oldcFlying then
                pings.EZAnims_cFly(cFlying)
            end
            oldcFlying = cFlying

            updateTimer = updateTimer + 1
            if updateTimer % 200 == 0 then
                pings.EZAnims_cFly(cFlying)
            end
        end
    end

    local pose = player:getPose()
    local velocity = player:getVelocity()
    local moving = velocity.xz:length() > 0.01
    local sprinty = player:isSprinting()
    local vehicle = player:getVehicle()
    local sitting = vehicle ~= nil or pose == "SITTING" -- if you're reading this code and see this, "SITTING" isn't a vanilla pose, this is for mods
    local passenger = vehicle and vehicle:getControllingPassenger() ~= player
    local creativeFlying = (flying or false) and not sitting
    local crouching = player:isCrouching() and not creativeFlying
    local gliding = player:isGliding()
    local spin = player:riptideSpinning()
    local swimming = player:isVisuallySwimming() or pose == "CRAWLING"
    local sleeping = pose == "SLEEPING" and not (crouching or gliding or spin or swimming)
    local standing = not (crouching or gliding or spin or sleeping or swimming)
    local inWater = player:isUnderwater() and not sitting
    local inLiquid = player:isInWater() or player:isInLava()
    local liquidSwim = swimming and inLiquid
    local crawling = swimming and not inLiquid

    -- hasJumped stuff
    
    yvel = velocity.y
    local hover = yvel < .01 and yvel > -.01
    local goingUp = yvel > .01
    local goingDown =  yvel < -.01
    local falling = yvel < fallVel
    local playerGround = world.getBlockState(player:getPos():add(0,-.1,0))
    local vehicleGround = sitting and world.getBlockState(vehicle:getPos():add(0,-.1,0))
    oldgrounded = grounded
    grounded = playerGround:isSolidBlock() or player:isOnGround() or (sitting and vehicleGround:isSolidBlock() or sitting and vehicle:isOnGround())

    local pv = velocity:mul(1, 0, 1):normalize()
    local pl = models:partToWorldMatrix():applyDir(0,0,-1):mul(1, 0, 1):normalize()
    local fwd = pv:dot(pl)
    local backwards = fwd < -.8
    --local sideways = pv:cross(pl)
    --local right = sideways.y > .6
    --local left = sideways.y < -.6

    -- canJump stuff
    local webbed = world.getBlockState(player:getPos()).id == "minecraft:cobweb"
    local ladder = player:isClimbing() and not grounded and not flying

    local canJump = not (inLiquid or webbed or grounded)

    local hp = player:getHealth() + player:getAbsorptionAmount()

    if oldgrounded ~= grounded and not grounded and yvel > 0 then
        cooldown = true
        timer = 0
    end
    if timer < 11 then
        timer = timer + 1
    end
    if timer == 11 then
        cooldown = false
    end

    if (oldgrounded ~= grounded and not grounded and yvel > 0) and canJump then hasJumped = true end
    if (grounded and (yvel <= 0 and yvel > -0.1)) or (gliding or inLiquid) then hasJumped = false end

    local neverJump = not (gliding or spin or sleeping or swimming or ladder)
    local jumpingUp = hasJumped and goingUp and neverJump
    local jumpingDown = hasJumped and goingDown and not falling and neverJump or (cooldown and not jumpingUp)
    local isJumping = jumpingUp or jumpingDown or falling
    local sprinting = sprinty and standing and not inLiquid and not sitting
    local walking = moving and not sprinting and not isJumping and not sitting
    local forward = walking and not backwards
    local backward = walking and backwards

    jumpTracker = isJumping and not creativeFlying and not falling and not ladder and not sitting -- only used for isJumping

    local handedness = player:isLeftHanded()
    local rightItem = player:getHeldItem(handedness)
    local leftItem = player:getHeldItem(not handedness)
    local rightActive = handedness and "OFF_HAND" or "MAIN_HAND"
    local leftActive = not handedness and "OFF_HAND" or "MAIN_HAND"
    local activeness = player:getActiveHand()
    local using = player:isUsingItem()
    local rightSuccess = pcall(rightItem.getUseAction,rightItem)
    if rightSuccess then rightResult = rightItem:getUseAction() else rightResult = "NONE" end
    local usingR = using and activeness == rightActive and rightResult
    local leftSuccess = pcall(leftItem.getUseAction,leftItem)
    if leftSuccess then leftResult = leftItem:getUseAction() else leftResult = "NONE" end
    local usingL = using and activeness == leftActive and leftResult
    local swing = player:getSwingTime()
    local arm = swing == 1 and not sleeping and player:getSwingArm()
    local rTag= rightItem.tag
    local lTag = leftItem.tag
    local crossR = rTag and (rTag["Charged"] == 1 or (rTag["ChargedProjectiles"] and next(rTag["ChargedProjectiles"])~= nil)) or false
    local crossL = lTag and (lTag["Charged"] == 1 or (lTag["ChargedProjectiles"] and next(lTag["ChargedProjectiles"])~= nil)) or false
    local exclude = not (crossR or crossL or using)
    local game = player:getGamemode()
    local reach = game and 6 or 3

    if swing == 1 then
        targetEntity = type(player:getTargetedEntity(reach)) == "PlayerAPI" or type(player:getTargetedEntity(reach)) == "LivingEntityAPI"
        rightMine = oldhitBlock and not targetEntity
        leftMine = oldhitBlock and not targetEntity
        rightAttack = (not oldhitBlock or targetEntity)
        leftAttack = (not oldhitBlock or targetEntity)
    end

    for _,o in pairs(objects) do

        o.diff = false
        for types, tabs in pairs(o.overriders) do
           o.overrideStates[types] = o.setOverrides[types] or false
            for _, value in pairs(tabs) do
                if getPlay(value) then
                    o.overrideStates[types] = true
                    break
                end
            end
            if o.oldoverStates[types] ~= o.overrideStates[types] then
                o.diff = true
            end
            o.oldoverStates[types] = o.overrideStates[types]
        end

        local ob = o.aList
    
        ob.flywalkback.active = creativeFlying and backward and (not (goingDown or goingUp))
        ob.flysprint.active = creativeFlying and sprinting and not isJumping and (not (goingDown or goingUp))
        ob.flyup.active = creativeFlying and goingUp
        ob.flydown.active = creativeFlying and goingDown
        ob.flywalk.active = creativeFlying and forward and (not (goingDown or goingUp)) and not sleeping or (ob.flysprint.active and next(ob.flysprint.list)==nil) or (ob.flywalkback.active and next(ob.flywalkback.list)==nil)
        or (ob.flyup.active and next(ob.flyup.list)==nil) or (ob.flydown.active and next(ob.flydown.list)==nil)
        ob.fly.active = creativeFlying and not sprinting and not moving and standing and not isJumping and (not (goingDown or goingUp)) and not sleeping or (ob.flywalk.active and next(ob.flywalk.list)==nil)

        ob.watercrouchwalkback.active = inWater and crouching and backward and not goingDown
        ob.watercrouchwalk.active = inWater and crouching and forward and not (goingDown or goingUp) or (ob.watercrouchwalkback.active and next(ob.watercrouchwalkback.list)==nil)
        ob.watercrouchup.active = inWater and crouching and goingUp
        ob.watercrouchdown.active = inWater and crouching and goingDown or (ob.watercrouchup.active and next(ob.watercrouchup.list)==nil)
        ob.watercrouch.active = inWater and crouching and not moving and not (goingDown or goingUp) or (ob.watercrouchdown.active and next(ob.watercrouchdown.list)==nil) or (ob.watercrouchwalk.active and next(ob.watercrouchwalk.list)==nil)

        ob.waterdown.active = inWater and goingDown and not falling and standing and not creativeFlying
        ob.waterup.active = inWater and goingUp and standing and not creativeFlying
        ob.waterwalkback.active = inWater and backward and hover and standing and not creativeFlying
        ob.waterwalk.active = inWater and forward and hover and standing and not creativeFlying or (ob.waterwalkback.active and next(ob.waterwalkback.list)==nil) or (ob.waterdown.active and next(ob.waterdown.list)==nil)
        or (ob.waterup.active and next(ob.waterup.list)==nil)
        ob.water.active = inWater and not moving and standing and hover and not creativeFlying or (ob.waterwalk.active and next(ob.waterwalk.list)==nil)
        


        ob.crawlstill.active = crawling and not moving
        ob.crawl.active = crawling and moving or (ob.crawlstill.active and next(ob.crawlstill.list)==nil)

        ob.swim.active = liquidSwim or (ob.crawl.active and next(ob.crawl.list)==nil)

        ob.elytradown.active = gliding and goingDown
        ob.elytra.active = gliding and not goingDown or (ob.elytradown.active and next(ob.elytradown.list)==nil)

        ob.sitpass.active = passenger and standing or false
        ob.sitjumpdown.active = sitting and not passenger and standing and (jumpingDown or falling)
        ob.sitjumpup.active = sitting and not passenger and jumpingUp and standing or (ob.sitjumpdown.active and next(ob.sitjumpdown.list)==nil)
        ob.sitmoveback.active = sitting and not passenger and not isJumping and backwards and standing
        ob.sitmove.active = velocity:length() > 0 and not passenger and not backwards and standing and sitting and not isJumping or (ob.sitmoveback.active and next(ob.sitmoveback.list)==nil) or (ob.sitjumpup.active and next(ob.sitjumpup.list)==nil)
        ob.sit.active = sitting and not passenger and velocity:length() == 0 and not isJumping and standing or (ob.sitmove.active and next(ob.sitmove.list)==nil) or (ob.sitpass.active and next(ob.sitpass.list)==nil) or false

        ob.trident.active = spin
        ob.sleep.active = sleeping
        ob.climbcrouchwalk.active = ladder and crouching and not inWater and (moving or yvel ~= 0)
        ob.climbcrouch.active = ladder and crouching and hover and not moving or (ob.climbcrouchwalk.active and next(ob.climbcrouchwalk.list)==nil)
        ob.climbdown.active = ladder and goingDown and not crouching
        ob.climbstill.active = ladder and not crouching and hover
        ob.climb.active = ladder and goingUp and not crouching or (ob.climbdown.active and next(ob.climbdown.list)==nil) or (ob.climbstill.active and next(ob.climbstill.list)==nil)

        ob.crouchjumpdown.active = crouching and jumpingDown and not inWater and not ladder
        ob.crouchjumpup.active = crouching and jumpingUp and not inWater and not ladder or (not oneJump and (ob.crouchjumpdown.active and next(ob.crouchjumpdown.list)==nil))
        ob.crouchwalkback.active = backward and crouching and not gliding and not inWater and not ladder or (ob.watercrouchwalkback.active and next(ob.watercrouchwalkback.list)==nil and next(ob.watercrouchwalk.list)==nil and next(ob.watercrouch.list)==nil)
        ob.crouchwalk.active = forward and crouching and not gliding and not (jumpingDown or jumpingUp) and not inWater and not ladder or (ob.crouchwalkback.active and next(ob.crouchwalkback.list)==nil) or (not oneJump and (ob.crouchjumpup.active and next(ob.crouchjumpup.list)==nil)) or ((ob.watercrouchwalk.active and not ob.watercrouchwalkback.active) and next(ob.watercrouchwalk.list)==nil and next(ob.watercrouch.list)==nil)
        ob.crouch.active = crouching and not walking and not inWater and not isJumping and not ladder and not cooldown or (ob.crouchwalk.active and next(ob.crouchwalk.list)==nil) or (ob.climbcrouch.active and next(ob.climbcrouch.list)==nil) or ((ob.watercrouch.active and not ob.watercrouchwalk.active) and next(ob.watercrouch.list)==nil)
        
        ob.fall.active = falling and not gliding and not creativeFlying and not sitting and not crouching or (ob.crouchfall.active and next(ob.crouchfall.list)==nil)
        ob.crouchfall.active = falling and not gliding and not creativeFlying and not sitting and crouching
        
        ob.sprintjumpdown.active = jumpingDown and sprinting and not creativeFlying and not ladder or false
        ob.sprintjumpup.active = jumpingUp and sprinting and not creativeFlying and not ladder or (not oneJump and (ob.sprintjumpdown.active and next(ob.sprintjumpdown.list)==nil)) or false
        ob.walkjumpdown.active = jumpingDown and moving and not ladder and not sprinting and not crouching and not sitting and not sleeping and not gliding and not creativeFlying and not spin and not inWater
        ob.walkjumpup.active = jumpingUp and moving and not ladder and not sprinting and not crouching and not sitting and not creativeFlying and not inWater or (not oneJump and (ob.walkjumpdown.active and next(ob.walkjumpdown.list)==nil)) or false
        ob.jumpdown.active = jumpingDown and not moving and not ladder and not sprinting and not crouching and not sitting and not sleeping and not gliding and not creativeFlying and not spin and not inWater or (ob.fall.active and next(ob.fall.list)==nil) or (oneJump and (ob.sprintjumpdown.active and next(ob.sprintjumpdown.list)==nil)) or (oneJump and (ob.crouchjumpdown.active and next(ob.crouchjumpdown.list)==nil)) or (oneJump and (ob.walkjumpdown.active and next(ob.walkjumpdown.list)==nil))
        ob.jumpup.active = jumpingUp and not moving and not ladder and not sprinting and not crouching and not sitting and not creativeFlying and not inWater or (ob.jumpdown.active and next(ob.jumpdown.list)==nil) or (ob.trident.active and next(ob.trident.list)==nil) or (oneJump and (ob.sprintjumpup.active and next(ob.sprintjumpup.list)==nil)) or (oneJump and (ob.walkjumpup.active and next(ob.walkjumpup.list)==nil))

        if grounded ~= oldgrounded and not grounded then
            if (ob.jumpup.active and next(ob.jumpdown.list)==nil) then
                ob.jumpup.active = false
                setAnimation("jumpup",getOverriders(ob.jumpup.type,o),getStates(ob.jumpup.type,o),o)
                ob.jumpup.active = true
                setAnimation("jumpup",getOverriders(ob.jumpup.type,o),getStates(ob.jumpup.type,o),o)
            elseif (ob.walkjumpup.active and next(ob.walkjumpdown.list)==nil) then
                ob.walkjumpup.active = false
                setAnimation("walkjumpup",getOverriders(ob.walkjumpup.type,o),getStates(ob.walkjumpup.type,o),o)
                ob.walkjumpup.active = true
                setAnimation("walkjumpup",getOverriders(ob.walkjumpup.type,o),getStates(ob.walkjumpup.type,o),o)
            elseif (ob.sprintjumpup.active and next(ob.sprintjumpdown.list)==nil) then
                ob.sprintjumpup.active = false
                setAnimation("sprintjumpup",getOverriders(ob.sprintjumpup.type,o),getStates(ob.sprintjumpup.type,o),o)
                ob.sprintjumpup.active = true
                setAnimation("sprintjumpup",getOverriders(ob.sprintjumpup.type,o),getStates(ob.sprintjumpup.type,o),o)
            elseif (ob.crouchjumpup.active and next(ob.crouchjumpdown.list)==nil) then
                ob.crouchjumpup.active = false
                setAnimation("crouchjumpup",getOverriders(ob.crouchjumpup.type,o),getStates(ob.crouchjumpup.type,o),o)
                ob.crouchjumpup.active = true
                setAnimation("crouchjumpup",getOverriders(ob.crouchjumpup.type,o),getStates(ob.crouchjumpup.type,o),o)
            elseif (ob.sitjumpup.active and next(ob.sitjumpdown.list)==nil) then
                ob.sitjumpup.active = false
                setAnimation("sitjumpup",getOverriders(ob.sitjumpup.type,o),getStates(ob.sitjumpup.type,o),o)
                ob.sitjumpup.active = true
                setAnimation("sitjumpup",getOverriders(ob.sitjumpup.type,o),getStates(ob.sitjumpup.type,o),o)
            end
        end

        ob.sprint.active = sprinting and not isJumping and not creativeFlying and not ladder and not cooldown and not inWater or (not oneJump and (ob.sprintjumpup.active and next(ob.sprintjumpup.list)==nil)) or false
        ob.walkback.active = backward and standing and not creativeFlying and not ladder and not inWater or (ob.flywalkback.active and next(ob.flywalkback.list)==nil and next(ob.flywalk.list)==nil and next(ob.fly.list)==nil)
        ob.walk.active = forward and standing and not creativeFlying and not ladder and not cooldown and not inWater or (ob.walkback.active and next(ob.walkback.list)==nil) or (ob.sprint.active and next(ob.sprint.list)==nil) or (ob.climb.active and next(ob.climb.list)==nil)
        or (ob.swim.active and next(ob.swim.list)==nil) or (ob.elytra.active and next(ob.elytra.list)==nil) or (ob.waterwalk.active and (next(ob.waterwalk.list)==nil and next(ob.water.list)==nil)) or ((ob.flywalk.active and not ob.flywalkback.active) and next(ob.flywalk.list)==nil and next(ob.fly.list)==nil)
        or (ob.crouchwalk.active and (next(ob.crouchwalk)==nil and next(ob.crouch.list)==nil)) or (not oneJump and ob.walkjumpup.active and next(ob.walkjumpup.list)==nil)
        ob.idle.active = not moving and not sprinting and standing and not isJumping and not sitting and not inWater and not creativeFlying and not ladder or (ob.sleep.active and next(ob.sleep.list)==nil) or (ob.sit.active and next(ob.sit.list)==nil)
        or ((ob.water.active and not ob.waterwalk.active) and next(ob.water.list)==nil) or ((ob.fly.active and not ob.flywalk.active) and next(ob.fly.list)==nil) or ((ob.crouch.active and not ob.crouchwalk.active) and next(ob.crouch.list)==nil) or (ob.jumpup.active and next(ob.jumpup.list)==nil)

        ob.death.active = hp <= 0
        ob.hurt.active = oldhp ~= hp and hp < oldhp

        ob.attackR.active = arm == rightActive and rightAttack
        ob.attackL.active = arm == leftActive and leftAttack
        ob.mineR.active = arm == rightActive and rightMine
        ob.mineL.active = arm == leftActive and leftMine
        ob.holdR.active = rightItem.id~="minecraft:air" and exclude
        ob.holdL.active = leftItem.id~="minecraft:air" and exclude
        ob.eatR.active = usingR == "EAT"
        ob.eatL.active = usingL == "EAT"
        ob.drinkR.active = usingR == "DRINK"
        ob.drinkL.active = usingL == "DRINK"
        ob.blockR.active = usingR == "BLOCK"
        ob.blockL.active = usingL == "BLOCK"
        ob.bowR.active = usingR == "BOW"
        ob.bowL.active = usingL == "BOW"
        ob.loadR.active = usingR == "CROSSBOW"
        ob.loadL.active = usingL == "CROSSBOW"
        ob.crossR.active = crossR
        ob.crossL.active = crossL
        ob.spearR.active = usingR == "SPEAR"
        ob.spearL.active = usingL == "SPEAR"
        ob.spyglassR.active = usingR == "SPYGLASS"
        ob.spyglassL.active = usingL == "SPYGLASS"
        ob.hornR.active = usingR == "TOOT_HORN"
        ob.hornL.active = usingL == "TOOT_HORN"
        ob.brushR.active = usingR == "BRUSH"
        ob.brushL.active = usingL == "BRUSH"

        for key,value in pairs(o.aList) do
            if (value.active ~= o.oldList[key].active) then
                setAnimation(key,getOverriders(value.type,o),getStates(value.type,o),o)
            end
            if (o.toggleDiff or o.diff) and value.active then
                setAnimation(key,getOverriders(value.type,o),getStates(value.type,o),o)
            end
            o.oldList[key].active = value.active
        end

        o.toggleDiff = false
        for key,_ in pairs(o.toggleState) do
            if o.oldToggle[key] ~= o.toggleState[key] then
                o.toggleDiff = true
            end
            o.oldToggle[key] = o.toggleState[key]
        end
    end
    oldhp = hp
    oldhitBlock = hitBlock
    targetBlock = player:getTargetedBlock(true, game and 5 or 4.5)
    blockSuccess, blockResult = pcall(targetBlock.getTextures, targetBlock)
    if blockSuccess then hitBlock = not (next(blockResult) == nil) else hitBlock = true end
end

function events.tick()
    getInfo()
end

local function getBBModels()
    local bbmodels = {}
    for _,layer in pairs(models:getChildren()) do
        local name = layer:getName()
        if animations[name] then
            bbmodels[name] = animations[name]
        else
            for _,layer2 in pairs(layer:getChildren()) do
                local name2 = name.."."..layer2:getName()
                bbmodels[name2] = animations[name2]
            end
        end
    end

    if next(bbmodels) == nil then
        error("No blockbench models containing animations were found.")
    end

    local aList = {}
    local oldList = {}
    for _, value in pairs(exList) do
        aList[value] = {active = false,list = {},type = "excluAnims"}
        oldList[value] = {active = false}
    end

    for _, value in pairs(incList) do
        aList[value] = {active = false,list = {},type = "incluAnims"}
        oldList[value] = {active = false}
    end

    aList.attackR.stop = true
    aList.attackL.stop = true
    aList.mineR.stop = true
    aList.mineL.stop = true
    aList.hurt.stop = true

    local o = setmetatable(
    {
        bbmodels=bbmodels,
        aList=aList,
        oldList=oldList,
        toggleState = {excluAnims="",incluAnims=""},
        oldToggle = {excluAnims="",incluAnims=""},
        toggleDiff = toggleDiff,
        overriders = {excluAnims = {},incluAnims = {}, allAnims = {}},
        overrideStates = {excluAnims = false,incluAnims = false, allAnims = false},
        oldoverStates = {excluAnims = false,incluAnims = false, allAnims = false},
        setOverrides = {excluAnims = false,incluAnims = false, allAnims = false},
        diff = diff
    }, 
    controllerMT)
    objects[1] = o
    addAnims(bbmodels,o)
end

function events.entity_init()
    if #objects == 0 then getBBModels() end
end

local firstRun = true
---@param ... table
function anims:addBBModel(...)
    local bbmodels = {...}
    if next(bbmodels) == nil then
        error("The blockbench model provided couldn't be found because it has no animations, or because of a typo or some other mistake.",2)
    end

    local aList = {}
    local oldList = {}
    for _, value in pairs(exList) do
        aList[value] = {active = false,list = {},type = "excluAnims"}
        oldList[value] = {active = false}
    end

    for _, value in pairs(incList) do
        aList[value] = {active = false,list = {},type = "incluAnims"}
        oldList[value] = {active = false}
    end

    aList.attackR.stop = true
    aList.attackL.stop = true
    aList.mineR.stop = true
    aList.mineL.stop = true
    aList.hurt.stop = true

    local o = setmetatable(
    {
        bbmodels=bbmodels,
        aList=aList,
        oldList=oldList,
        toggleState = {excluAnims="",incluAnims=""},
        oldToggle = {excluAnims="",incluAnims=""},
        toggleDiff = toggleDiff,
        overriders = {excluAnims = {},incluAnims = {}, allAnims = {}},
        overrideStates = {excluAnims = false,incluAnims = false, allAnims = false},
        oldoverStates = {excluAnims = false,incluAnims = false, allAnims = false},
        setOverrides = {excluAnims = false,incluAnims = false, allAnims = false},
        diff = diff
    }, 
    controllerMT)
    objects[#objects+1] = o 
    if #objects == 16 then
        error("The max amount of blockbench models (16) was reached. Do not put the code for adding blockbench models in a function, it will infinitely add blockbench models.",3)
    end
    if auto then addAnims(bbmodels,o) end
    return o
end

anims.controller = controller
return anims