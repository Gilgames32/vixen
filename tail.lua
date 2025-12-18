-- inspired by Auriafoxgirl

local tail = models.model.root.Tail.Actual
local tailTarget = models.model.root.Tail.Target

local oldBodyRot = vec(0, 0, 0)
local oldTailRot = tail:getRot()
local newTailRot = oldTailRot

local wagStrenghtMax = 0.75
local wagSpeed = 0.75
local oldWagTime = 0
local oldWagStrenght = 0
local newWagTime = 0
local newWagStrenght = 0

-- clamp an angle between min and max
local function clampAngle(angle, min, max)
    angle = math.shortAngle(0, angle)
    if angle < min then
        return min
    elseif angle > max then
        return max
    end
    return angle
end

-- lerp an angle depending on the cosine of how close it is to the target, minimum delta can be specified
local function cosLerpAngle(from, to, range, minDelta)
    local distance = math.shortAngle(from, to)
    local delta = (1 - math.cos(math.clamp(distance / range, -1, 1) * math.pi)) / 2
    delta = math.max(minDelta, delta)
    return math.lerpAngle(from, to, delta)
end

function events.tick()
    -- get player velocity
    local bodyRot = player:getBodyYaw(1)
    local playerVel = vectors.rotateAroundAxis(bodyRot, player:getVelocity(), vec(0, 1, 0))
    
    -- body pitch
    local bodyPitch = 0
    local playerPose = player:getPose()
    local waterStrength = 1
    local wagWalkSpeed = 1
    if playerPose == "SWIMMING" then
        if #world.getBlockState(player:getPos()):getFluidTags() >= 1 then
            bodyPitch = -90 - player:getRot().x
        else
            bodyPitch = -90
        end
        waterStrength = 0.5
    elseif playerPose == "FALL_FLYING" or playerPose == "SPIN_ATTACK" then
        bodyPitch = -90 - player:getRot().x
        wagWalkSpeed = 0
    end
    local playerVelRaw = vectors.rotateAroundAxis(bodyPitch, playerVel, vec(1, 0, 0))

    -- calculate body rotation difference
    local newBodyRot = vec(bodyPitch, bodyRot, 0)
    local deltaBodyRot = newBodyRot - oldBodyRot
    oldBodyRot = newBodyRot
    -- calculate world space tail rotation 
    oldTailRot = newTailRot
    newTailRot = newTailRot + deltaBodyRot

    -- target tail rotation
    local targetRot = tailTarget:getRot()

    -- rotate tail based on velocity while its not animated
    if tailTarget:getAnimRot():lengthSquared() == 0 then
        local velRot = vec(
            math.clamp(playerVelRaw.y, -1, 1) * 90 - math.clamp(playerVelRaw.z, -0.5, 0.5) * 90,
            playerVelRaw.x * 45,
            0
        )
        targetRot = targetRot + velRot
    end

    -- limit angles
    targetRot.x = clampAngle(targetRot.x, -45, 60)
    targetRot.y = clampAngle(targetRot.y, -60, 60)
    -- lerp towards the target angle
    newTailRot.x = cosLerpAngle(newTailRot.x, targetRot.x, 90, 0.1)
    newTailRot.y = cosLerpAngle(newTailRot.y, targetRot.y, 180, 0.1)

    -- calculate wag time
    oldWagTime = newWagTime 
    newWagTime = newWagTime + math.min(1, math.sqrt(math.abs(playerVel.z / 0.32))) * wagSpeed * waterStrength * wagWalkSpeed
    if newWagTime > 2 * math.pi then -- overflow for better precision
        newWagTime = newWagTime - 2 * math.pi
        oldWagTime = oldWagTime - 2 * math.pi
    end
    -- calculate wag strenght
    oldWagStrenght = newWagStrenght
    newWagStrenght = math.lerp(newWagStrenght, playerVel.z * waterStrength * wagWalkSpeed, 0.1)

end

function events.render(delta)
    -- interpolate wag values
    local wagTime = math.lerp(oldWagTime, newWagTime, delta)
    local wagStrenght = math.lerp(oldWagStrenght, newWagStrenght, delta)
    local wagRot = vec(0, math.deg((math.cos(wagTime))) * wagStrenght * wagStrenghtMax, 0)
    -- interpolate rotation
    local iRot = math.lerpAngle(oldTailRot, newTailRot, delta)
    tail:setRot(iRot + wagRot)
end