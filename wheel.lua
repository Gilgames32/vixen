local mainpage = action_wheel:newPage("mainPage")
action_wheel:setPage(mainpage)

mainpage:newAction()
    :setTitle("yip")
    :setItem("minecraft:sweet_berries")
    :onLeftClick(function(active)
        sounds:playSound("minecraft:entity.fox.sleep", player:getPos())
    end)
