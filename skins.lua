local wheel = require("wheel")

-- automatic skin updated based on the biome
local auto = false
local skinUpdateInterval = 80
local skinUpdateTimer = 0

local skinEntries = {
    Rebecca = {
        texture = "skin_rebecca",
        icon = "minecraft:redstone",
        name = [=[[{"text":"Rebecca","color":"gold"}]]=],
    },
    Mira = {
        texture = "skin_mira",
        icon = "minecraft:target",
        name = [=[[{"text":"Mira","color":"red"}]]=],
    },
    Eva = {
        texture = "skin_eva",
        icon = "minecraft:crimson_nylium",
        name = [=[[{"text":"Eva","color":"dark_red"}]]=],
    },
    Rue = {
        texture = "skin_rue",
        icon = "minecraft:red_sand",
        name = [=[[{"text":"Rue","color":"gold"}]]=],
    },
    Kaya = {
        texture = "skin_kaya",
        icon = "minecraft:snow_block",
        name = [=[[{"text":"Kaya","color":"white"}]]=],
    },
}
local currentSkin = skinEntries.Rebecca
nameplate.ALL:setText(currentSkin.name)

local isSleeping = false
local function setSkinSleeping(enabled)
    if isSleeping == enabled then return end
    isSleeping = enabled
    models.model.root.Head:setPrimaryTexture("CUSTOM", textures[enabled and (currentSkin.texture .. "_sleep") or currentSkin.texture])
end
local function setSkin(skin)
    if currentSkin == skin then return end
    models.model.root:setPrimaryTexture("CUSTOM", textures[skin.texture])
    currentSkin = skin
    nameplate.ALL:setText(skin.name)
end

-- skin entries
for key, value in pairs(skinEntries) do
    wheel.skinPage:newAction()
    :setTitle(key)
    :setItem(value.icon)
    :onLeftClick(function (_)
        auto = false
        setSkin(value)
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