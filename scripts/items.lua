require("scripts.util")

local itemsExtra = {
    "minecraft:emerald",
    "minecraft:feather",
    "minecraft:egg",
    "minecraft:totem_of_undying",
    "minecraft:shears",
    "minecraft:flint_and_steel",
    "minecraft:redstone",
    "minecraft:milk_bucket",
    "minecraft:book",
}

local toolsExtra = {
    "minecraft:trident",
    "minecraft:mace",
    "minecraft:fishing_rod",
    "minecraft:fishing_rod",
    "minecraft:bone",
    "minecraft:stick",
}

local function isMouthTool(item)
    if item:isTool() then return true end
    if item.id:find("_sword") then return true end
    return contains(toolsExtra, item.id)
end

local function isMouthItem(item)
    if item:isFood() then return true end
    return contains(itemsExtra, item.id)
end

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
    
    local item = isMouthItem(mainHandItem)
    local tool = isMouthTool(mainHandItem)
    local block = contains(blocks, mainHandItem.id)
    local sprinting = player:isSprinting()

    if block then
        animations.model.blockhold:play()
    else
        animations.model.blockhold:stop()
    end
    enderIP:setParentType((block and not sprinting) and "RightItemPivot" or "None")
    
    rightIP:setParentType((not handedness and not item and not block and not (tool and sprinting)) and "RightItemPivot" or "None")
    -- TODO fix pivot breaking when the secondary arms parent type is changed 
    --leftIP:setParentType((handedness and not isItem and not isTool) and "LeftItemPivot" or "None")
    
    mouthIP:setParentType((item) and (handedness and "LeftItemPivot" or "RightItemPivot") or "None")
    mouthTP:setParentType((tool and sprinting) and (handedness and "LeftItemPivot" or "RightItemPivot") or "None")
end