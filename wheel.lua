require("util")

local soundboardEntries = {
    ambient = {
        icon = "minecraft:sweet_berries",
        sound = "minecraft:entity.fox.ambient",
    },
    bite = {
        icon = "minecraft:chicken",
        sound = "minecraft:entity.fox.bite",
    },
    eat = {
        icon = "minecraft:cooked_chicken",
        sound = "minecraft:entity.fox.eat",
    },
    aggro = {
        icon = "minecraft:pufferfish",
        sound = "minecraft:entity.fox.aggro",
    },
    screech = {
        icon = "minecraft:music_disc_11",
        sound = "minecraft:entity.fox.screech",
    },
    sniff = {
        icon = "minecraft:feather",
        sound = "minecraft:entity.fox.sniff",
    },
    spit = {
        icon = "minecraft:arrow",
        sound = "minecraft:entity.fox.spit",
    },
    -- hurt = {
    --     icon = "minecraft:heartbreak_pottery_sherd",
    --     sound = "minecraft:entity.fox.hurt",
    -- },
    sleep = {
        icon = "minecraft:red_bed",
        sound = "minecraft:entity.fox.sleep",
    },
}

local skinEntries = {
    Rebecca = {
        texture = "skin_rebecca",
        icon = "minecraft:command_block",
    },
    Mira = {
        texture = "skin_mira",
        icon = "minecraft:target",
    },
    Eva = {
        texture = "skin_eva",
        icon = "minecraft:crimson_nylium",
    },
    Rue = {
        texture = "skin_rue",
        icon = "minecraft:red_sand",
    },
    Kaya = {
        texture = "skin_kaya",
        icon = "minecraft:snow_block",
    },
}

-- page history for backing
local history = {}
local function back()
    local last = history[#history]
    if last then
        action_wheel:setPage(last)
        table.remove(history, #history)
    end
end
local function openPage(page)
    table.insert(history, action_wheel:getCurrentPage())
    action_wheel:setPage(page)
end

-- go back with rmb
function events.mouse_press(button, action, modifier)
    if button == 1 and action == 1 and action_wheel:isEnabled() then
        back()
    end
end

-- pages
local mainPage = action_wheel:newPage("main page")
local soundboardPage = action_wheel:newPage("sounds")
local skinPage = action_wheel:newPage("skins")
action_wheel:setPage(mainPage)

-- main page entries
mainPage:newAction()
:setTitle("soundboard")
:setItem("minecraft:note_block")
:onLeftClick(function(_)
    openPage(soundboardPage)
end)

mainPage:newAction()
:setTitle("skins")
:setItem("minecraft:armor_stand")
:onLeftClick(function (_)
    openPage(skinPage)
end)

-- soundboard entries
for key, value in pairs(soundboardEntries) do
    soundboardPage:newAction()
    :setTitle(key)
    :setItem(value.icon)
    :onLeftClick(function (_)
        playerSound(value.sound)
    end)
end


for key, value in pairs(skinEntries) do
    skinPage:newAction()
    :setTitle(key)
    :setItem(value.icon)
    :onLeftClick(function (_)
        models.model.root:setPrimaryTexture("CUSTOM", textures[value.texture])
    end)
end