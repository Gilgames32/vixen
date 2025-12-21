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
action_wheel:setPage(mainPage)

-- main page entries
mainPage:newAction()
:setTitle("soundboard")
:setItem("minecraft:note_block")
:onLeftClick(function(_)
    openPage(soundboardPage)
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
-- soundboardPage:newAction()
-- :setTitle("back")
-- :setItem("minecraft:barrier")
-- :onLeftClick(function (_)
--     back()
-- end)