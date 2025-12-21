require("util")

local items = {
    "minecraft:emerald",
    "minecraft:chicken",
    "minecraft:cooked_chicken",
    "minecraft:feather",
    "minecraft:egg",
}

local tools = {
    "minecraft:wooden_pickaxe",
    "minecraft:wooden_sword",
}

local blocks = {
    --"minecraft:grass_block",
}

local mouthIP = models.model.root.Head.MouthIPivot
local mouthTP = models.model.root.Head.MouthTPivot
local rightIP = models.model.root.RightArm.RightItemPivot
local leftIP = models.model.root.LeftArm.LeftItemPivot
local enderIP = models.model.root.EnderIPivot

function events.tick()
    local handedness = false -- TODO player:isLeftHanded()
    local mainHandItem = player:getHeldItem(handedness)
    
    local isItem = contains(items, mainHandItem.id)
    local isTool = contains(tools, mainHandItem.id)
    local isBlock = contains(blocks, mainHandItem.id)
    local isSprinting = player:isSprinting()

    if isBlock then
        animations.model.blockhold:play()
    else
        animations.model.blockhold:stop()
    end
    enderIP:setParentType((isBlock and not isSprinting) and "RightItemPivot" or "None")
    
    rightIP:setParentType((not handedness and not isItem and not isBlock and not (isTool and isSprinting)) and "RightItemPivot" or "None")
    -- TODO fix pivot breaking when the secondary arms parent type is changed 
    --leftIP:setParentType((handedness and not isItem and not isTool) and "LeftItemPivot" or "None")
    
    mouthIP:setParentType((isItem) and (handedness and "LeftItemPivot" or "RightItemPivot") or "None")
    mouthTP:setParentType((isTool and isSprinting) and (handedness and "LeftItemPivot" or "RightItemPivot") or "None")
end