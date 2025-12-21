require("util")

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


return {
    mainPage = mainPage,
    skinPage = skinPage,
    soundboardPage= soundboardPage,
}