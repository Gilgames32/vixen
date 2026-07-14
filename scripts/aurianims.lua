---@class aurianims
local lib = {}
---@class aurianims.controller
local animController = {}
animController.__index = animController
---@class aurianims.node
local nodeClass = {type = nil}

local controllers = {}

---creates new animation controller
---@return aurianims.controller
function lib.new()
   local obj = {
      data = {},
      tree = {}
   }
   setmetatable(obj, animController)
   table.insert(controllers, obj)
   return obj
end

---sets function that can add data that can be later used in nodes, returns self for selfchaining
---@param func fun(data: table)
---@param startData table?
---@return aurianims.controller
function animController:setDriver(func, startData)
   self.dataFunc = func
   if startData then
      self.data = startData
   end
   return self
end

---sets tree of nodes with animations, returns self for selfchaining
---@param tree aurianims.node
---@return aurianims.controller
function animController:setTree(tree)
   self.tree = tree
   return self
end

---creates mix node, mix function return value controls what animation should be used 0 is 100% of anim1 and 0% of anim2, 1 is 0% of anim1 and 100% of anim2, values below 0 or above 1 will be clamped 
---@param func fun(data: table, old: number, anim1: aurianims.node|Animation, anim2: aurianims.node|Animation): blend: number, instant: boolean?
---@param anim1 aurianims.node|Animation
---@param anim2 aurianims.node|Animation
---@return aurianims.node
function lib.mix(func, anim1, anim2)
   return {
      type = 'mix',
      func = func,
      anim1 = anim1,
      anim2 = anim2,
      blend = 0,
      oldBlend = 0
   }
end

---creates stack node, allows to use multiple animations or nodes at once
---@param anims aurianims.node[]|Animation[]
---@return aurianims.node
function lib.stack(anims)
   return {
      type = 'stack',
      anims = anims
   }
end

---creates blend node, allows to control how much animation will be used depending on return value from function 
---@param func fun(data: table, old: number, anim: aurianims.node|Animation): blend: number, instant: boolean?
---@param anim any
---@return table
function lib.blend(func, anim)
   return {
      type = 'blend',
      func = func,
      anim = anim,
      blend = 0,
      oldBlend = 0
   }
end

---creates step mode, allow choose between two animations depending on a predicate function, if predicate returns true anim1 will be used, if false anim2 will be used
---@param func fun(data: table): boolean
---@param anim1 aurianims.node|Animation
---@param anim2 aurianims.node|Animation
---@return aurianims.node
function lib.step(func, anim1, anim2)
   return {
      type = 'step',
      func = func,
      anim1 = anim1,
      anim2 = anim2
   }
end

---creates multi step node, allows to choose between multiple animations depending on a predicate function, the function should return the name of the animation that should be used
---@param func fun(data: table): string
---@param anims table<string, aurianims.node|Animation>
---@return aurianims.node
function lib.switch(func, anims)
   return {
      type = 'switch',
      func = func,
      anims = anims
   }
end

---creates vanilla leaf node, allows to use vanilla animations with blending
---@param parts ModelPart[]
---@return aurianims.node
function lib.vanilla(parts)
   local part_list = {}

   for _, part in ipairs(parts) do
      local vpart = part:getParentType():gsub("([a-z])([A-Z])", "%1_%2"):upper()
      if vanilla_model[vpart] then
         part_list[vpart] = part_list[vpart] or {}
         part_list[vpart][#part_list[vpart] + 1] = part
      end
   end
   
   return {
      type = 'vanilla',
      part_list = part_list
   }
end

local nodesUpdate
local function update(controller, node, blend)
   if type(node) == 'Animation' then
      node:setPlaying(blend > 0.001)
      return
   elseif node == nil then
      return
   end
   nodesUpdate[node.type](controller, node, blend)
end

nodesUpdate = {
   mix = function(controller, node, blendMul)
      node.oldBLend = node.blend
      local blend, instant = node.func(controller.data, node.blend, node.anim1, node.anim2)
      blend = math.clamp(blend, 0, 1)
      node.blend = blend
      if instant then node.oldBLend = blend end
      update(controller, node.anim1, blendMul * (1 - blend))
      update(controller, node.anim2, blendMul * blend)
   end,
   stack = function(controller, node, blendMul)
      for _, v in pairs(node.anims) do
         update(controller, v, blendMul)
      end
   end,
   blend = function(controller, node, blendMul)
      node.oldBLend = node.blend
      local blend, instant = node.func(controller.data, node.blend, node.anim1, node.anim2)
      blend = math.clamp(blend, 0, 1)
      node.blend = blend
      if instant then node.oldBLend = blend end
      update(controller, node.anim, blendMul * blend)
   end,
   step = function(controller, node, blendMul)
      local pred = node.func(controller.data)
      update(controller, node.anim1, blendMul * (pred and 1 or 0))
      update(controller, node.anim2, blendMul * (pred and 0 or 1))
   end,
   switch = function(controller, node, blendMul)
      local pred = node.func(controller.data)
      for k, v in pairs(node.anims) do
         update(controller, v, blendMul * (k == pred and 1 or 0))
      end
   end,
   vanilla = function(controller, node, blendMul)
      -- leaf
   end,
}


local nodesUpdateRender
local function updateRender(delta, controller, node, blend)
   if type(node) == 'Animation' then
      node:blend(blend)
      return
   elseif node == nil then
      return
   end
   nodesUpdateRender[node.type](delta, controller, node, blend)
end

nodesUpdateRender = {
   mix = function(delta, controller, node, blendMul)
      local blend = math.lerp(node.oldBLend, node.blend, delta)
      updateRender(delta, controller, node.anim1, blendMul * (1 - blend))
      updateRender(delta, controller, node.anim2, blendMul * blend)
   end,
   stack = function(delta, controller, node, blendMul)
      for _, v in pairs(node.anims) do
         updateRender(delta, controller, v, blendMul)
      end
   end,
   blend = function(delta, controller, node, blendMul)
      local blend = math.lerp(node.oldBLend, node.blend, delta)
      updateRender(delta, controller, node.anim, blendMul * blend)
   end,
   step = function(delta, controller, node, blendMul)
      local pred = node.func(controller.data)
      updateRender(delta, controller, node.anim1, blendMul * (pred and 1 or 0))
      updateRender(delta, controller, node.anim2, blendMul * (pred and 0 or 1))
   end,
   switch = function(delta, controller, node, blendMul)
      local pred = node.func(controller.data)
      for k, v in pairs(node.anims) do
         updateRender(delta, controller, v, blendMul * (k == pred and 1 or 0))
      end
   end,
   vanilla = function(delta, controller, node, blendMul)
      for name, parts in pairs(node.part_list) do
         local rot = vanilla_model[name]:getOriginRot()
         if name == "HEAD" then
            rot[2] = ((rot[2] + 180) % 360) - 180
         end
         rot:scale(blendMul)

         for _, p in ipairs(parts) do
            -- blend only if the part has an override to avoide double vanilla rotation
            if p:overrideVanillaRot() then
               p:offsetRot(rot)
            else
               p:offsetRot(vec(0, 0, 0))
            end
         end
      end
   end,
}

function events.tick()
   for _, v in pairs(controllers) do
      if v.dataFunc then
         v.dataFunc(v.data)
      end
      update(v, v.tree, 1)
   end
end

function events.render(delta)
   for _, v in pairs(controllers) do
      updateRender(delta, v, v.tree, 1)
   end
end

return lib