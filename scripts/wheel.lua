require("scripts.util")

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
local animPage = action_wheel:newPage("animations")
local settingsPage = action_wheel:newPage("settings")
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
:setItem("minecraft:rabbit_hide")
:onLeftClick(function (_)
    openPage(skinPage)
end)

mainPage:newAction()
:setTitle("animations")
:setItem("minecraft:armor_stand")
:onLeftClick(function (_)
    openPage(animPage)
end)

mainPage:newAction()
:setTitle("settings")
:setItem("minecraft:totem_of_undying")
:onLeftClick(function (_)
    openPage(settingsPage)
end)

return {
    mainPage = mainPage,
    skinPage = skinPage,
    soundboardPage= soundboardPage,
    animPage = animPage,
    settingsPage = settingsPage,
}