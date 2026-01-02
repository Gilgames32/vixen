local wheel = require("scripts.wheel")

wheel.settingsPage:newAction()
:setTitle("disable custom nameplate")
:setItem("minecraft:name_tag")
:onToggle(function (state)
    pings.setNamePlate(not state)
end)