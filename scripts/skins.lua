local wheel = require("scripts.wheel")

-- automatic skin updated based on the biome
local auto = false
local skinUpdateInterval = 80
local skinUpdateTimer = 0

local skinEntries = {
    Rebecca = {
        texture = "assets.skin_rebecca",
        icon = "minecraft:redstone",
        name = [=[[{"text":"Rebecca","color":"gold"}]]=],
    },
    Mira = {
        texture = "assets.skin_mira",
        icon = "minecraft:target",
        name = [=[[{"text":"Mira","color":"red"}]]=],
    },
    Eva = {
        texture = "assets.skin_eva",
        icon = "minecraft:crimson_nylium",
        name = [=[[{"text":"Eva","color":"dark_red"}]]=],
    },
    Rue = {
        texture = "assets.skin_rue",
        icon = "minecraft:red_sand",
        name = [=[[{"text":"Rue","color":"gold"}]]=],
    },
    Kaya = {
        texture = "assets.skin_kaya",
        icon = "minecraft:snow_block",
        name = [=[[{"text":"Kaya","color":"white"}]]=],
    },
    Thea = {
        texture = "assets.skin_thea",
        icon = "minecraft:coal_block",
        name = [=[[{"text":"Thea","color":"dark_gray"}]]=],
    },
    --[[ remove this line and its pair to uncomment and enable the custom skin

    -- replace "Custom" to the name that should show in the tooltip when selecting the skin
    Custom = {
        texture = "assets.skin_custom",
        -- change this to the block/item you want as the icon
        icon = "minecraft:structure_block",
        -- change this to the display name you want (https://minecraft.tools/en/json_text.php)
        -- dont forget the [=[...]=] to escape special characters
        name = [=[ [{"text":"Cu","color":"dark_aqua"},{"text":"s","color":"green"},{"text":"t","color":"yellow"},{"text":"om","color":"red"}] ]=],
    },
    
    ]]-- the pair line in question that you also have to remove
}
-- change this to false if you want to keep your vanilla username
local overridePlayerName = true
-- change this to your custom skin entry to make it the default
-- for example skinEntries.Custom, or whatever you have changed it to
local currentSkin = skinEntries.Rebecca

function pings.setNamePlate(override)
    nameplate.ALL:setText(override and currentSkin.name or "${name}")
    overridePlayerName = override
end
pings.setNamePlate(overridePlayerName)

local isSleeping = false
local function setSkinSleepingTexture(enabled)
    models.model.root.Head:setPrimaryTexture("CUSTOM", textures[enabled and (currentSkin.texture .. "_sleep") or currentSkin.texture])
end
local function setSkinSleeping(enabled)
    if isSleeping == enabled then return end
    isSleeping = enabled
    setSkinSleepingTexture(isSleeping)
end
function pings.setSkinSleeping(enabled)
    setSkinSleepingTexture(enabled)
end
local function setSkin(skin)
    if currentSkin == skin then return end
    currentSkin = skin
    models.model.root:setPrimaryTexture("CUSTOM", textures[skin.texture])
    setSkinSleepingTexture(isSleeping)
    pings.setNamePlate(overridePlayerName)
end
function pings.setSkin(skin)
    setSkin(skin)
end

-- skin entries
for key, value in pairs(skinEntries) do
    wheel.skinPage:newAction()
    :setTitle(key)
    :setItem(value.icon)
    :onLeftClick(function (_)
        auto = false
        pings.setSkin(value)
    end)
end
wheel.skinPage:newAction()
:setTitle("auto")
:setItem("minecraft:command_block")
:onLeftClick(function (_)
    auto = true
    skinUpdateTimer = skinUpdateInterval
end)


local function autoSkin()
    -- eva in nether
    local dimension = world.getDimension()
    if dimension == "minecraft:the_nether" then
        setSkin(skinEntries.Eva)
        return
    end
    -- mira in end
    if dimension == "minecraft:the_end" then
        setSkin(skinEntries.Mira)
        return
    end

    local biome = world.getBiome(player:getPos())
    local temperature = biome:getTemperature()
    
    -- kaya in cold 
    if temperature <= 0.25 then
        setSkin(skinEntries.Kaya)
        return
    end

    -- eva in dark forests
    if biome.id == "minecraft:dark_forest" then
        setSkin(skinEntries.Eva)
        return
    end

    setSkin(skinEntries.Rue)
end

function events.tick()
    setSkinSleeping(player:getPose() == "SLEEPING")

    if not auto then return end
    if skinUpdateTimer < skinUpdateInterval then
        skinUpdateTimer = skinUpdateTimer + 1
        return
    else
        skinUpdateTimer = 0
    end

    autoSkin()
end