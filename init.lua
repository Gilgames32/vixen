-- vanilla overrides
vanilla_model.PLAYER:setVisible(false)
vanilla_model.ARMOR:setVisible(false)
vanilla_model.HELMET_ITEM:setVisible(true)
vanilla_model.HELMET:setVisible(true)
vanilla_model.CAPE:setVisible(false)
--vanilla_model.ELYTRA:setVisible(false)

-- nameplate
nameplate.ALL:setText([=[[{"text":"Mira","color":"red"}]]=])

-- loading notification
function events.entity_init()
    sounds:playSound("minecraft:entity.fox.ambient", player:getPos())
end
