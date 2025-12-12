--hide vanilla model
vanilla_model.PLAYER:setVisible(false)

--hide vanilla armor model
vanilla_model.ARMOR:setVisible(false)
--re-enable the helmet item
vanilla_model.HELMET_ITEM:setVisible(true)
vanilla_model.HELMET:setVisible(true)

--hide vanilla cape model
vanilla_model.CAPE:setVisible(false)

--hide vanilla elytra model
--vanilla_model.ELYTRA:setVisible(false)

nameplate.ALL:setText([=[[{"text":"Vixen","color":"gold"},{"text":" :fox:"}]]=])

--entity init event, used for when the avatar entity is loaded for the first time
function events.entity_init()
  --player functions goes here
  sounds:playSound("minecraft:entity.fox.ambient", player:getPos())
end

--tick event, called 20 times per second
function events.tick()
  --code goes here
end

--render event, called every time your avatar is rendered
--it have two arguments, "delta" and "context"
--"delta" is the percentage between the last and the next tick (as a decimal value, 0.0 to 1.0)
--"context" is a string that tells from where this render event was called (the paperdoll, gui, player render, first person)
function events.render(delta, context)
  --code goes here
end
