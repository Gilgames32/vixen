-- ┌───┐                ┌───┐ --
-- │ ┌─┘ ┌─────┐┌─────┐ └─┐ │ --
-- │ │   │ ┌───┘│ ╶───┤   │ │ --
-- │ │   │ ├───┐└───┐ │   │ │ --
-- │ │   │ └─╴ │┌───┘ │   │ │ --
-- │ └─┐ └─────┘└─────┘ ┌─┘ │ --
-- └───┘                └───┘ --
---@module  "Animation Blending Library" <GSAnimBlend>
---@version v2.4.0
---@see     GrandpaScout @ https://github.com/GrandpaScout
-- Adds prewrite-like animation blending to the rewrite.
-- Also includes the ability to modify how the blending works per-animation with blending callbacks.
--
-- Simply `require`ing this library is enough to make it run. However, if you place this library in a variable, you can
-- get access to functions and tools that allow for generating built-in blending callbacks or creating your own blending
-- callbacks.
--
-- This library is fully documented. If you use Sumneko's Lua Language server, you will get descriptions of each
-- function, method, and field in this library.

local ID = "GSAnimBlend"
local VER = "2.4.0"
local FIG = {"0.1.0-rc.14", "0.1.5"}

-- Safe version comparison --
local CLIENT_VERSION = client.getFiguraVersion()
    :match("^([^%+]*)")
    :gsub("^([pr])", "0.1.3-%1")
local COMPARABLE_VERSION = CLIENT_VERSION
  :gsub("^(%d+).-%..-(%d+).-%..-(%d+).-(%-?)", "%1.%2.%3%4")

local cmp = function(to)
  local s, r = pcall(client.compareVersions, COMPARABLE_VERSION, to)
  return s and r or nil
end
-----------------------------

---@type boolean, Lib.GS.AnimBlend
local s, this = pcall(function()
  --|================================================================================================================|--
  --|=====|| SCRIPT ||===============================================================================================|--
  --||==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==||--

  -- Localize Lua basic
  local getmetatable = getmetatable
  local setmetatable = setmetatable
  local type = type
  local assert = assert
  local error = error
  local next = next
  local ipairs = ipairs
  local pairs = pairs
  local rawset = rawset
  local tostring = tostring
  -- Localize Lua libraries
  local math = math
  local m_abs = math.abs
  local m_cos = math.cos
  local m_lerp = math.lerp
  local m_map = math.map
  local m_max = math.max
  local m_sin = math.sin
  local m_sqrt = math.sqrt
  local m_pi = math.pi
  local m_1s2pi = m_pi * 0.5
  local m_2s3pi = m_pi / 1.5
  local m_4s9pi = m_pi / 2.25
  -- Localize Figura globals
  local animations = animations
  local figuraMetatables = figuraMetatables
  local vanilla_model = vanilla_model
  local events = events
  -- Localize current environment
  local _ENV = _ENV --[[@as _G]]

  ---@diagnostic disable: duplicate-set-field, duplicate-doc-field

  ---This library is used to allow prewrite-like animation blending with one new feature with infinite
  ---possibility added on top.  
  ---Any fields, functions, and methods injected by this library will be prefixed with
  ---**[GS&nbsp;AnimBlend&nbsp;Library]** in their description.
  ---
  ---If this library is required without being stored to a variable, it will automatically set up the
  ---blending features.  
  ---If this library is required *and* stored to a variable, it will also contain tools for generating
  ---pre-built blending callbacks and creating custom blending callbacks.
  ---```lua
  ---require "···"
  --- -- OR --
  ---local anim_blend = require "···"
  ---```
  ---@class Lib.GS.AnimBlend
  ---This library's perferred ID.
  ---@field _ID string
  ---This library's version.
  ---@field _VERSION string
  local this = {
    ---Enables error checking in the library. `true` by default.
    ---
    ---Turning off error checking will greatly reduce the amount of instructions used by this library
    ---at the cost of not telling you when you put in a wrong value.
    ---
    ---If an error pops up while this is `false`, try setting it to `true` and see if a different
    ---error pops up.
    safe = true
  }
  local thismt = {
    __type = ID,
    __metatable = false,
    __index = {
      _ID = ID,
      _VERSION = VER
    }
  }

  -- Create private space for blending trigger.
  -- This is done non-destructively so other scripts may do this as well.
  if not getmetatable(_ENV) then setmetatable(_ENV, {}) end


  -----======================================= VARIABLES ========================================-----

  local _ENVMT = getmetatable(_ENV)


  ---Contains the data required to make animation blending for each animation.
  ---@type {[Animation]: Lib.GS.AnimBlend.AnimData}
  local animData = {}

  ---Contains the currently blending animations.
  ---@type {[Animation]?: true}
  local blending = {}

  this.animData = animData
  this.blending = blending

  local ticker = 0
  local last_delta = 0
  local allowed_contexts = {
    RENDER = true,
    FIRST_PERSON = true,
    OTHER = true
  }


  -----=================================== UTILITY FUNCTIONS ====================================-----

  local chk = {}

  chk.types = {
    ["nil"] = "nil",
    boolean = "boolean",
    number = "number",
    string = "string",
    table = "table",
    ["function"] = "function"
  }

  function chk.badarg(i, name, got, exp, opt)
    if opt and got == nil then return true end
    local gotT = type(got)
    local gotType = chk.types[gotT] or "userdata"

    local expType = chk.types[exp] or "userdata"
    if gotType ~= expType then
      if expType == "function" and gotType == "table" then
        local mt = getmetatable(got)
        if mt and mt.__call then return true end
      end
      return false, ("bad argument #%s to '%s' (%s expected, got %s)")
        :format(i, name, expType, gotType)
    elseif expType ~= exp and gotT ~= exp then
      return false, ("bad argument #%s to '%s' (%s expected, got %s)")
        :format(i, name, exp, gotType)
    end

    return true
  end

  function chk.badnum(i, name, got, opt)
    if opt and got == nil then
      return true
    elseif type(got) ~= "number" then
      local gotType = chk.types[type(got)] or "userdata"
      return false, ("bad argument #%s to '%s' (number expected, got %s)"):format(i, name, gotType)
    elseif got * 0 ~= 0 then
      return false, ("bad argument #%s to '%s' (value cannot be %s)"):format(i, name, got)
    end

    return true
  end

  local function makeSane(val, def)
    return val * 0 == 0 and val or def
  end


  -----=================================== PREPARE ANIMATIONS ===================================-----

  ---Creates an animation data table for any user-created object.  
  ---It is your responsibility to keep the object updated if necessary.
  ---
  ---If `proxy` is set, that table will be used to store the data.  
  ---* It will not have its metatable modified.
  ---* Its `__index` method (if it exists) will be triggered for each key that has a default value to see.
  ---* Its `__newindex` method (if it exists) will be triggered for each missing key that gets a default value.
  ---* It will be returned by this function.
  ---
  ---Do not provide a proxy if you do not intend to actually use it. If no proxy is provided, a more efficient method of
  ---generating the data will be used.
  ---@param obj table | userdata
  ---@param proxy? table
  ---@return Lib.GS.AnimBlend.AnimData
  function this.newAnimData(obj, proxy)
    if proxy then
      animData[obj] = proxy
      if proxy["EZAnims$hasBlendTime"] == nil then proxy["EZAnims$hasBlendTime"] = false end
      if proxy.blendTimeIn == nil then proxy.blendTimeIn = 0 end
      if proxy.blendTimeOut == nil then proxy.blendTimeOut = 0 end
      if proxy.blend == nil then proxy.blend = obj.getBlend and obj:getBlend() or 0 end
      if proxy.blendSane == nil then proxy.blendSane = makeSane(proxy.blend, 0) end
      if proxy.length == nil then proxy.length = obj.getLength and makeSane(obj:getLength(), false) or 0 end
      if proxy.triggerId == nil then proxy.triggerId = -1 end
      if proxy.callbacks == nil then proxy.callbacks = {} end
      if proxy.callbacksCache == nil then proxy.callbacksCache = {priority_0 = 1, use_default = true} end
      if proxy.model == nil then proxy.model = "<UNKNOWN>" end
      -- if proxy.startFunc == nil then proxy.startFunc = nil end
      -- if proxy.startSource == nil then proxy.startSource = nil end
      -- if proxy.endFunc == nil then proxy.endFunc = nil end
      -- if proxy.endSource == nil then proxy.endSource = nil end
      return proxy
    end

    local data = {
      ["EZAnims$hasBlendTime"] = false,
      blendTimeIn = 0,
      blendTimeOut = 0,
      triggerId = -1,
      callbacks = {},
      callbacksCache = {priority_0 = 1, use_default = true},
      model = "<UNKNOWN>"
    }

    if type(obj) == "Animation" then
      local blend = obj:getBlend()
      data.blend = blend
      data.blendSane = makeSane(blend, 0)
      data.length = makeSane(obj:getLength(), false)
    else
      local blend = obj.getBlend and obj:getBlend()
      data.blend = blend or 0
      data.blendSane = blend and makeSane(blend, 0) or 0
      data.length = obj.getLength and makeSane(obj:getLength(), false) or 0
    end

    animData[obj] = data
    return data
  end
  local newAnimData = this.newAnimData

  local animPause
  local blendCommand = [[getmetatable(_ENV).GSLib_triggerBlend[%d](%s, ...)]]

  _ENVMT.GSLib_triggerBlend = {}

  ---@type {mdl: string, name: string, code: {time: number, src: string}[]?}[]?
  local anim_nbt = avatar:getNBT().animations
  if anim_nbt then
    for i, nbt in ipairs(anim_nbt) do
      local anim = animations[nbt.mdl][nbt.name]
      local len = anim:getLength()

      ---@type fun(...: any)?, fun(...: any)?
      local start_func, end_func
      ---@type string?, string?
      local start_src, end_src
      if nbt.code then
        for _, code in ipairs(nbt.code) do
          if code.time == 0 then
            start_src = code.src
            start_func = load(start_src, ("animations.%s.%s"):format(nbt.mdl, nbt.name))
          elseif code.time == len then
            end_src = code.src
            end_func = load(end_src, ("animations.%s.%s"):format(nbt.mdl, nbt.name))
          end
          if start_func and (len == 0 or end_func) then break end
        end
      end

      local data = newAnimData(anim)
      data.triggerId = i
      data.model = nbt.mdl
      data.startFunc = start_func
      data.startSource = start_src
      data.endFunc = end_func
      data.endSource = end_src

      _ENVMT.GSLib_triggerBlend[i] = function(at_start, ...)
        if
          anim:getLoop() == "ONCE"
          and (data.blendTimeOut > 0)
          and (at_start == nil or (anim:getSpeed() < 0) == at_start)
        then
          animPause(anim)
          anim:stop()
        end

        if at_start == false then
          if data.endFunc then data.endFunc(...) end
        elseif data.startFunc then
          data.startFunc(...)
        end
      end

      local lenSane = makeSane(len, false)
      if lenSane == 0 then
        anim:newCode(0, blendCommand:format(i, "nil"))
      else
        anim:newCode(0, blendCommand:format(i, "true"))
        if lenSane then anim:newCode(lenSane, blendCommand:format(i, "false")) end
      end
    end
  end


  -----============================ PREPARE METATABLE MODIFICATIONS =============================-----

  local animation_mt = figuraMetatables.Animation
  local animationapi_mt = figuraMetatables.AnimationAPI

  local ext_Animation = next(animData)
  if not ext_Animation then
    error(
      "No animations have been found!\n" ..
      "This library cannot build its functions without an animation to use.\n" ..
      "Create an animation or stop this library from running to fix the error."
    )
  end


  -- Check for conflicts
  if ext_Animation.setBlendTime or ext_Animation.blendTime then
    local this_path = tostring(makeSane):match("^function: (.-):%d+%-%d+$")
    local other_path = tostring(ext_Animation.setBlendTime or ext_Animation.blendTime):match("^function: (.-):%d+%-%d+$")
    error(
      ("Conflict found!\n§7[§e%s.lua§7]§4 conflicts with §7[§e%s.lua§7]§4\nRemove one of the above scripts to fix this conflict.")
        :format(this_path, other_path)
    )
  end

  local _animationIndex = animation_mt.__index
  local _animationNewIndex = animation_mt.__newindex or rawset
  local _animationapiIndex = animationapi_mt.__index

  local animPlay = ext_Animation.play
  local animStop = ext_Animation.stop
  animPause = ext_Animation.pause
  local animRestart = ext_Animation.restart
  local animBlend = ext_Animation.blend
  local animLength = ext_Animation.length
  local animTime = ext_Animation.time
  local animGetPlayState = ext_Animation.getPlayState
  local animGetBlend = ext_Animation.getBlend
  local animGetTime = ext_Animation.getTime
  local animIsPlaying = ext_Animation.isPlaying
  local animIsPaused = ext_Animation.isPaused
  local animNewCode = ext_Animation.newCode
  local animPlaying = ext_Animation.playing
  local animapiGetPlaying = animations.getPlaying

  ---Contains the old functions, just in case you need direct access to them again.
  ---
  ---These are useful for creating your own blending callbacks.
  this.oldF = {
    play = animPlay,
    stop = animStop,
    pause = animPause,
    restart = animRestart,

    getBlend = animGetBlend,
    getPlayState = animGetPlayState,
    getTime = animGetTime,
    isPlaying = animIsPlaying,
    isPaused = animIsPaused,

    setBlend = ext_Animation.setBlend,
    setLength = ext_Animation.setLength,
    setPlaying = ext_Animation.setPlaying,

    blend = animBlend,
    length = animLength,
    playing = animPlaying,

    api_getPlaying = animapiGetPlaying
  }


  -----===================================== SET UP LIBRARY =====================================-----

  ---Library-defined Animation method overrides will be disabled for any Animation in this set.
  ---
  ---Note: This only disables *overrides*. New methods defined by this library will not be disabled.
  ---@type {[Animation]?: true}
  local mt_bypass = {
    check = function(self, obj) return self[obj] and self[obj] > 0 or false end,
    push = function(self, obj) self[obj] = (self[obj] or 0) + 1 end,
    pop = function(self, obj) self[obj] = self[obj] > 1 and (self[obj] - 1) or nil end,
  }

  local function isAnimationObject(obj)
    if obj["GSAnimBlend$isAnimationObject"] ~= true or not animData[obj] then error() end
  end

  ---Causes a blending event to happen and returns the blending state for that event.  
  ---If a blending event could not happen for some reason, nothing will be returned.
  ---
  ---If `time`, `from`, or `to` are `nil`, they will take from the animation's data to determine this
  ---value.
  ---
  ---One of `from` or `to` *must* be set.
  ---
  ---If `starting` is given, it will be used instead of the guessed value from the data given.
  ---@param anim Animation
  ---@param time? number
  ---@param from? number
  ---@param to? number
  ---@param starting? boolean
  ---@return Lib.GS.AnimBlend.BlendState?
  function this.blend(anim, time, from, to, starting)
    local isanimobj = type(anim) ~= "Animation" and pcall(isAnimationObject, anim)
    if this.safe then
      if not isanimobj then assert(chk.badarg(1, "blend", anim, "Animation")) end
      assert(chk.badarg(2, "blend", time, "number", true))
      assert(chk.badarg(3, "blend", from, "number", true))
      assert(chk.badarg(4, "blend", to, "number", true))
      if not from and not to then error("one of arguments #3 or #4 must be a number", 2) end
    end

    mt_bypass:push(anim)

    local data = animData[anim]
    local blendSane = data.blendSane

    if starting == nil then
      starting = (from or blendSane) < (to or blendSane)
    end

    if not player:isLoaded() then
      anim:setPlaying(starting)
      mt_bypass:pop(anim)
      return nil
    end

    local callbacks_cache = data.callbacksCache
    if callbacks_cache.use_default then
      callbacks_cache[callbacks_cache.priority_0] = this.defaultCallback
    end


    data.state = {
      time = 0,
      max = time or false,

      from = from or false,
      to = to or false,

      callbacks = callbacks_cache,
      curve = data.curve or this.defaultCurve,

      paused = false,
      starting = starting,
      delay = starting and m_max(anim:getStartDelay() * 20, 0) or 0,

      callbackState = {
        anim = anim,
        time = 0,
        max = time or (starting and data.blendTimeIn or data.blendTimeOut),
        progress = 0,
        rawProgress = 0,
        from = from or blendSane,
        to = to or blendSane,
        starting = starting,
        done = false
      }
    }

    blending[anim] = true

    anim:setBlend(from or blendSane)
    if starting then
      anim:play()
      if anim:getSpeed() < 0 then
        anim:setTime(anim:getLength() - anim:getOffset())
      else
        anim:setTime(anim:getOffset())
      end
    end
    anim:pause()

    mt_bypass:pop(anim)
    return data.state
  end

  ---A helper function that immediately stops a running blend on an animation.  
  ---This function will do nothing if the animation is not blending.
  ---
  ---A blend stopped with this function will run its blending callback one final time to request cleanup and then
  ---complete the blend.
  ---
  ---If `starting` is not `nil`, it will override the blending state's `starting` field when determining what happens
  ---after the blend is stopped.
  ---@param anim Animation
  ---@param starting? boolean
  function this.stopBlend(anim, starting)
    local isanimobj = type(anim) ~= "Animation" and pcall(isAnimationObject, anim)
    if this.safe and not isanimobj then
      assert(chk.badarg(1, "stopBlend", anim, "Animation"))
    end

    if blending[anim] then
      mt_bypass:push(anim)

      local data = animData[anim]
      local state = data.state
      local cbs = state.callbackState
      cbs.progress = 1
      cbs.time = cbs.max
      cbs.done = true
      for _, cb in ipairs(state.callbacks) do cb(cbs, data) end
      blending[anim] = nil
      anim:setBlend(data.blend)

      if starting ~= nil then
        anim:setPlaying(starting)
      else
        anim:setPlaying(state.starting)
      end
      mt_bypass:pop(anim)
    end
  end


  -----==================================== PRESET CALLBACKS ====================================-----

  ---Contains blending callbacks and callback generators.
  ---
  ---Callback generators are *not* callbacks themselves. They are meant to be called to generate a callback which can
  ---*then* be used.
  local callbackFunction = {}

  ---Contains custom blending curves.
  ---
  ---These callbacks change the easing curve used when blending.
  local easingCurve = {}


  ---===== CALLBACK FUNCTIONS =====---

  ---The base blending callback used by GSAnimBlend.  
  ---Does the bare minimum of setting the blend weight of the animation to match the blend progress.
  ---@param state Lib.GS.AnimBlend.CallbackState
  function callbackFunction.base(state)
    state.anim:setBlend(m_lerp(state.from, state.to, state.progress))
  end

  ---Given a list of parts, this will generate a blending callback that will blend between the vanilla
  ---parts' normal rotations and the rotations of the animation.
  ---
  ---The list of parts given is expected to the the list of parts that have a vanilla parent type in
  ---the chosen animation in no particular order.
  ---
  ---This callback *also* expects the animation to override vanilla rotations.
  ---
  ---Note: The resulting callback makes *heavy* use of `:offsetRot()` and will conflict with any other
  ---code that also uses that method!
  ---@param parts ModelPart[]
  ---@return Lib.GS.AnimBlend.blendCallback
  function callbackFunction.genBlendVanilla(parts)
    -- Because some dumbass won't read the instructions...
    ---@diagnostic disable-next-line: undefined-field
    if parts.done ~= nil then
      error("attempt to use generator 'genBlendVanilla' as a blend callback.", 2)
    end

    if this.safe then
      for i, part in ipairs(parts) do
        assert(chk.badarg("1[" .. i .. "]", "genBlendVanilla", part, "ModelPart"))
      end
    end

    ---@type {[string]: ModelPart[]}
    local part_list = {}
    local partscopy = {}

    -- Gather the vanilla parent of each part.
    for i, part in ipairs(parts) do
      partscopy[i] = part
      local vpart = part:getParentType():gsub("([a-z])([A-Z])", "%1_%2"):upper()
      if vanilla_model[vpart] then
        if not part_list[vpart] then part_list[vpart] = {} end
        local plvp = part_list[vpart]
        plvp[#plvp+1] = part
      end
    end

    -- The actual callback is created here.
    return function(state)
      if state.done then
        local id = "GSAnimBlend:BlendVanillaCleanup_" .. math.random(0, 0xFFFF)
        local events_render = events.RENDER
        local events_postworldrender = events.POST_WORLD_RENDER

        local function callback()
          for _, part in ipairs(partscopy) do part:offsetRot() end
          events_render:remove(id)
        end

        events_postworldrender:register(function()
          events_render:register(callback, id)
          events_postworldrender:remove(id)
        end, id)
      else
        local pct = state.starting and 1 - state.progress or state.progress

        for n, v in pairs(part_list) do
          ---@type Vector3
          local rot = vanilla_model[n]:getOriginRot()
          if n == "HEAD" then rot[2] = ((rot[2] + 180) % 360) - 180 end
          rot:scale(pct)
          for _, p in ipairs(v) do p:offsetRot(rot) end
        end

        state.anim:setBlend(m_lerp(state.from, state.to, state.progress))
      end
    end
  end

  ---Generates a callback that causes an animation to blend into another animation.
  ---@param anim Animation
  ---@return Lib.GS.AnimBlend.blendCallback
  function callbackFunction.genBlendTo(anim)
    -- Because some dumbass won't read the instructions...
    ---@diagnostic disable-next-line: undefined-field
    if anim.done ~= nil then
      error("attempt to use generator 'genBlendTo' as a blend callback.", 2)
    end

    if this.safe then
      assert(chk.badarg(1, "genBlendTo", anim, "Animation"))
    end

    ---This is used to track when the next animation should start blending.
    local ready = true

    return function(state, data)
      if state.done then
        ready = true
      else
        if not state.starting and ready then
          ready = false
          anim:play()
        end
        state.anim:setBlend(m_lerp(state.from, state.to, state.progress))
      end
    end
  end

  ---Generates a callback that forces all given animations to blend out if they are playing.
  ---@param anims Animation[]
  ---@return Lib.GS.AnimBlend.blendCallback
  function callbackFunction.genBlendOut(anims)
    -- Because some dumbass won't read the instructions...
    ---@diagnostic disable-next-line: undefined-field
    if anims.done ~= nil then
      error("attempt to use generator 'genBlendOut' as a blend callback.", 2)
    end

    if this.safe then
      for i, anim in ipairs(anims) do
        assert(chk.badarg("1[" .. i .. "]", "genBlendOut", anim, "Animation"))
      end
    end

    local ready = true

    return function(state)
      if state.done then
        ready = true
      else
        if state.starting and ready then
          ready = false
          for _, anim in ipairs(anims) do anim:stop() end
        end
        state.anim:setBlend(m_lerp(state.from, state.to, state.progress))
      end
    end
  end

  ---Generates a callback that plays one callback while blending in and another callback while blending out.
  ---
  ---If `nil` is given, the default callback is used.
  ---@param blend_in? Lib.GS.AnimBlend.blendCallback
  ---@param blend_out? Lib.GS.AnimBlend.blendCallback
  ---@return Lib.GS.AnimBlend.blendCallback
  function callbackFunction.genDualBlend(blend_in, blend_out)
    -- The dumbass check is a bit further down.

    local tbin, tbout = type(blend_in), type(blend_out)
    local infunc, outfunc = blend_in, blend_out
    if tbin == "table" then
      -- Because some dumbass won't read the instructions...
      ---@diagnostic disable-next-line: undefined-field
      if blend_in.done ~= nil then
        error("attempt to use generator 'genDualBlend' as a blend callback.", 2)
      end
      local mt = getmetatable(blend_in)
      if not (mt and mt.__call) then
        error("bad argument #1 to 'genDualBlend' (function expected, got " .. tbin .. ")")
      end
    else
      assert(chk.badarg(1, "genDualBlend", blend_in, "function", true))
    end

    if tbout == "table" then
      local mt = getmetatable(blend_out)
      if not (mt and mt.__call) then
        error("bad argument #2 to 'genDualBlend' (function expected, got " .. tbin .. ")")
      end
    else
      assert(chk.badarg(2, "genDualBlend", blend_out, "function", true))
    end

    return function(state, data)
      (state.starting and (infunc or this.defaultCallback) or (outfunc or this.defaultCallback))(state, data)
    end
  end

  ---Generates a callback that plays other callbacks on a timeline.
  ---
  ---Callbacks generated by this function *ignore easing curves in favor of the curves provided by the timeline*.
  ---
  ---An example of a valid timeline:
  ---```lua
  ---...genTimeline({
  ---  {time = 0, min = 0, max = 1, curve = "easeInSine"},
  ---  {time = 0.25, min = 1, max = 0.5, curve = "easeOutCubic"},
  ---  {time = 0.8, min = 0.5, max = 1, curve = "easeInCubic"}
  ---})
  ---```
  ---@param tl Lib.GS.AnimBlend.timeline
  ---@return Lib.GS.AnimBlend.blendCallback
  function callbackFunction.genTimeline(tl)
    -- Because some dumbass won't read the instructions...
    ---@diagnostic disable-next-line: undefined-field
    if tl.done ~= nil then
      error("attempt to use generator 'genTimeline' as a blend callback.", 2)
    end

    if this.safe then
      assert(chk.badarg(1, "genTimeline", tl, "table"))
      for i, kf in ipairs(tl) do
        assert(chk.badarg("1[" .. i .. "]", "genTimeline", kf, "table"))
      end
      local time = 0
      local ftime = tl[1].time
      if ftime ~= 0 then error("error in keyframe #1: timeline does not start at 0 (got " .. ftime .. ")") end
      for i, kf in ipairs(tl) do
        assert(chk.badnum("1[" .. i .. ']["time"]', "genTimeline", kf.time))
        if kf.time <= time then
          error(
            "error in keyframe #" .. i ..
            ": timeline did not move forward (from " .. time .. " to " .. kf.time .. ")", 2
          )
        end

        if kf.min then assert(chk.badnum("1[" .. i .. ']["min"]', "genTimeline", kf.min)) end
        if kf.max then assert(chk.badnum("1[" .. i .. ']["max"]', "genTimeline", kf.max)) end

        assert(chk.badarg("1[" .. i .. ']["callback"]', "genTimeline", kf.callback, "function", true))
        if type(kf.curve) ~= "string" then
          assert(chk.badarg("1[" .. i .. ']["curve"]', "genTimeline", kf.curve, "function", true))
        elseif not easingCurve[kf.curve] then
          error("bad argument 1[" .. i .. "][\"curve\"] of 'genTimeline' ('" .. kf.curve .. "' is not a valid curve)")
        end
      end
    end

    for _, kf in ipairs(tl) do
      if type(kf.curve) == "string" then
        kf.curve = easingCurve[kf.curve]
      end
    end

    return function(state, data)
      ---@type Lib.GS.AnimBlend.tlKeyframe, Lib.GS.AnimBlend.tlKeyframe
      local kf, nextkf
      for _, _kf in ipairs(tl) do
        if _kf.time > state.rawProgress then
          if _kf.time < 1 then nextkf = _kf end
          break
        end
        kf = _kf
      end

      local adj_prog = m_map(
        state.rawProgress,
        kf.time, nextkf and nextkf.time or 1,
        kf.min or 0, kf.max or 1
      )

      local newstate = setmetatable(
        {time = state.max * adj_prog, progress = (kf.curve or this.defaultCurve)(adj_prog)},
        {__index = state}
      );
      (kf.callback or this.defaultCallback)(newstate, data)
    end
  end


  ---===== EASING CURVES =====---

  ---The `linear` easing curve.
  ---
  ---This is the default curve used by GSAnimBlend.
  ---@param x number
  ---@return number
  function easingCurve.linear(x) return x end

  ---The `smoothstep` easing curve.
  ---
  ---This is a more performant, but slightly less accurate version of `easeInOutSine`.
  ---@param x number
  ---@return number
  function easingCurve.smoothstep(x) return x^2 * (3 - 2 * x) end

  -- I planned to add easeOutIn curves but I'm lazy. I'll do it if people request it.

  ---The [`easeInSine`](https://easings.net/#easeInSine) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeInSine(x) return 1 - m_cos(x * m_1s2pi) end

  ---The [`easeOutSine`](https://easings.net/#easeOutSine) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeOutSine(x) return m_sin(x * m_1s2pi) end

  ---The [`easeInOutSine`](https://easings.net/#easeInOutSine) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeInOutSine(x) return (m_cos(x * m_pi) - 1) * -0.5 end

  ---The [`easeInQuad`](https://easings.net/#easeInQuad) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeInQuad(x) return x^2 end

  ---The [`easeOutQuad`](https://easings.net/#easeOutQuad) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeOutQuad(x) return 1 - (1 - x)^2 end

  ---The [`easeInOutQuad`](https://easings.net/#easeInOutQuad) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeInOutQuad(x)
    return x < 0.5
      and 2 * x^2
      or 1 - (-2 * x + 2)^2 * 0.5
  end

  ---The [`easeInCubic`](https://easings.net/#easeInCubic) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeInCubic(x) return x^3 end

  ---The [`easeOutCubic`](https://easings.net/#easeOutCubic) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeOutCubic(x) return 1 - (1 - x)^3 end

  ---The [`easeInOutCubic`](https://easings.net/#easeInOutCubic) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeInOutCubic(x)
    return x < 0.5
      and 4 * x^3
      or 1 - (-2 * x + 2)^3 * 0.5
  end

  ---The [`easeInQuart`](https://easings.net/#easeInQuart) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeInQuart(x) return x^4 end

  ---The [`easeOutQuart`](https://easings.net/#easeOutQuart) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeOutQuart(x) return 1 - (1 - x)^4 end

  ---The [`easeInOutQuart`](https://easings.net/#easeInOutQuart) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeInOutQuart(x)
    return x < 0.5
      and 8 * x^4
      or 1 - (-2 * x + 2)^4 * 0.5
  end

  ---The [`easeInQuint`](https://easings.net/#easeInQuint) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeInQuint(x) return x^5 end

  ---The [`easeOutQuint`](https://easings.net/#easeOutQuint) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeOutQuint(x) return 1 - (1 - x)^5 end

  ---The [`easeInOutQuint`](https://easings.net/#easeInOutQuint) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeInOutQuint(x)
    return x < 0.5
      and 16 * x^5
      or 1 - (-2 * x + 2)^5 * 0.5
  end

  ---The [`easeInExpo`](https://easings.net/#easeInExpo) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeInExpo(x)
    return x == 0
      and 0
      or 2^(10 * x - 10)
  end

  ---The [`easeOutExpo`](https://easings.net/#easeOutExpo) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeOutExpo(x)
    return x == 1
      and 1
      or 1 - 2^(-10 * x)
  end

  ---The [`easeInOutExpo`](https://easings.net/#easeInOutExpo) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeInOutExpo(x)
    return (x == 0 or x == 1) and x
      or x < 0.5 and 2^(20 * x - 10) * 0.5
      or (2 - 2^(-20 * x + 10)) * 0.5
  end

  ---The [`easeInCirc`](https://easings.net/#easeInCirc) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeInCirc(x) return 1 - m_sqrt(1 - x^2) end

  ---The [`easeOutCirc`](https://easings.net/#easeOutCirc) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeOutCirc(x) return m_sqrt(1 - (x - 1)^2) end

  ---The [`easeInOutCirc`](https://easings.net/#easeInOutCirc) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeInOutCirc(x)
    return x < 0.5
      and (1 - m_sqrt(1 - (2 * x)^2)) * 0.5
      or (m_sqrt(1 - (-2 * x + 2)^2) + 1) * 0.5
  end

  ---The [`easeInBack`](https://easings.net/#easeInBack) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeInBack(x) return 2.70158 * x^3 - 1.70158 * x^2 end

  ---The [`easeOutBack`](https://easings.net/#easeOutBack) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeOutBack(x)
    x = x - 1
    return 1 + 2.70158 * x^3 + 1.70158 * x^2
  end

  ---The [`easeInOutBack`](https://easings.net/#easeInOutBack) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeInOutBack(x)
    x = x * 2
    return x < 1
      and (x^2 * (3.5949095 * x - 2.5949095)) * 0.5
      or ((x - 2)^2 * (3.5949095 * (x - 2) + 2.5949095) + 2) * 0.5
  end

  ---The [`easeInElastic`](https://easings.net/#easeInElastic) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeInElastic(x)
    return (x == 0 or x == 1) and x
      or -(2^(10 * x - 10)) * m_sin((x * 10 - 10.75) * m_2s3pi)
  end

  ---The [`easeOutElastic`](https://easings.net/#easeOutElastic) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeOutElastic(x)
    return (x == 0 or x == 1) and x
      or 2^(-10 * x) * m_sin((x * 10 - 0.75) * m_2s3pi) + 1
  end

  ---The [`easeInOutElastic`](https://easings.net/#easeInOutElastic) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeInOutElastic(x)
    return (x == 0 or x == 1) and x
      or x < 0.5 and -(2^(x * 20 - 10) * m_sin((x * 20 - 11.125) * m_4s9pi)) * 0.5
      or (2^(x * -20 + 10) * m_sin((x * 20 - 11.125) * m_4s9pi)) * 0.5 + 1
  end

  ---The [`easeInBounce`](https://easings.net/#easeInBounce) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeInBounce(x)
    x = 1 - x
    return 1 - (
      x < (1 / 2.75) and 7.5625 * x^2
      or x < (2 / 2.75) and 7.5625 * (x - 1.5 / 2.75)^2 + 0.75
      or x < (2.5 / 2.75) and 7.5625 * (x - 2.25 / 2.75)^2 + 0.9375
      or 7.5625 * (x - 2.625 / 2.75)^2 + 0.984375
    )
  end

  ---The [`easeOutBounce`](https://easings.net/#easeOutBounce) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeOutBounce(x)
    return x < (1 / 2.75) and 7.5625 * x^2
      or x < (2 / 2.75) and 7.5625 * (x - 1.5 / 2.75)^2 + 0.75
      or x < (2.5 / 2.75) and 7.5625 * (x - 2.25 / 2.75)^2 + 0.9375
      or 7.5625 * (x - 2.625 / 2.75)^2 + 0.984375
  end

  ---The [`easeInOutBounce`](https://easings.net/#easeInOutBounce) easing curve.
  ---@param x number
  ---@return number
  function easingCurve.easeInOutBounce(x)
    local s = x < 0.5 and -1 or 1
    x = x < 0.5 and 1 - 2 * x or 2 * x - 1
    return (1 + s * (
      x < (1 / 2.75) and 7.5625 * x^2
      or x < (2 / 2.75) and 7.5625 * (x - 1.5 / 2.75)^2 + 0.75
      or x < (2.5 / 2.75) and 7.5625 * (x - 2.25 / 2.75)^2 + 0.9375
      or 7.5625 * (x - 2.625 / 2.75)^2 + 0.984375
    )) * 0.5
  end


  do ---@source https://github.com/gre/bezier-easing/blob/master/src/index.js

    -- Bezier curves are extremely expensive to use especially with higher settings.
    -- Every function has been in-lined to improve instruction counts as much as possible.
    --
    -- In-lined functions are labeled with a --[[funcName(param1, paramN, ...)]]
    -- If an in-lined function spans more than one line, it will contain a #marker# that will appear later to close the
    -- function.
    --
    -- All of the functions below in the block comment are in-lined somewhere else.

    local default_subdiv_iters = 10
    local default_subdiv_prec = 0.0000001
    local default_newton_minslope = 0.001
    local default_newton_iters = 4
    local default_sample_size = 11

    --[=[
    local function _A(A1, A2) return 1.0 - 3.0 * A2 + 3.0 * A1 end
    local function _B(A1, A2) return 3.0 * A2 - 6.0 * A1 end
    local function _C(A1) return 3.0 * A1 end

    -- Returns x(t) given t, x1, and x2, or y(t) given t, y1, and y2.
    local function calcBezier(T, A1, A2)
      --[[((_A(A1, A2) * T + _B(A1, A2)) * T + _C(A1)) * T]]
      return (((1.0 - 3.0 * A2 + 3.0 * A1) * T + (3.0 * A2 - 6.0 * A1)) * T + (3.0 * A1)) * T
    end

    -- Returns dx/dt given t, x1, and x2, or dy/dt given t, y1, and y2.
    local function getSlope(T, A1, A2)
      --[[3.0 * _A(A1, A2) * T ^ 2 + 2.0 * _B(A1, A2) * T + _C(A1)]]
      return 3.0 * (1.0 - 3.0 * A2 + 3.0 * A1) * T ^ 2 + 2.0 * (3.0 * A2 - 6.0 * A1) * T + (3.0 * A1)
    end

    local function binarySubdivide(X, A, B, X1, X2)
      local curX, curT
      local iter = 0
      while (m_abs(curX) > SUBDIVISION_PRECISION and iter < SUBDIVISION_MAX_ITERATIONS) do
        curT = A + (B - A) * 0.5
        --[[calcBezier(curT, X1, X2) - X]]
        curX = ((((1.0 - 3.0 * X2 + 3.0 * X1) * curT + (3.0 * X2 - 6.0 * X1)) * curT + (3.0 * X1)) * curT) - X
        if curX > 0.0 then B = curT else A = curT end
        iter = iter + 1
      end
      return curT or (A + (B - A) * 0.5)
    end

    local function newtonRaphsonIterate(X, Tguess, X1, X2)
      for _ = 1, NEWTON_ITERATIONS do
        --[[getSlope(Tguess, X1, X2)]]
        local curSlope = 3.0 * (1.0 - 3.0 * X2 + 3.0 * X1) * Tguess ^ 2 + 2.0 * (3.0 * X2 - 6.0 * X1) * Tguess + (3.0 * X1)
        if (curSlope == 0.0) then return Tguess end
        --[[calcBezier(Tguess, X1, X2) - X]]
        local curX = ((((1.0 - 3.0 * X2 + 3.0 * X1) * Tguess + (3.0 * X2 - 6.0 * X1)) * Tguess + (3.0 * X1)) * Tguess) - X
        Tguess = Tguess - (curX / curSlope)
      end
      return Tguess
    end

    local function getTForX(X)
      local intervalStart = 0.0
      local curSample = 1
      local lastSample = SAMPLE_SIZE - 1

      while curSample ~= lastSample and SAMPLES[curSample] <= X do
        intervalStart = intervalStart + STEP_SIZE
        curSample = curSample + 1
      end
      curSample = curSample - 1

      -- Interpolate to provide an initial guess for t
      local dist = (X - SAMPLES[curSample]) / (SAMPLES[curSample + 1] - SAMPLES[curSample])
      local Tguess = intervalStart + dist * STEP_SIZE

      local initSlope = getSlope(Tguess, X1, X2)
      if (initSlope >= NEWTON_MIN_SLOPE) then
        return newtonRaphsonIterate(X, Tguess, X1, X2)
      elseif (initSlope == 0) then
        return Tguess
      else
        return binarySubdivide(X, intervalStart, intervalStart + STEP_SIZE, X1, X2)
      end
    end
    ]=]

    local BezierMT = {
      ---@param self Lib.GS.AnimBlend.Bezier
      __call = function(self, X)
        local X1, X2 = self[1], self[3]
        local Y1, Y2 = self[2], self[4]
        local T
        --[[getTForX(state.progress) #start getTForX#]]
        local intervalStart = 0
        local curSample = 1
        local lastSample = self.options.sample_size - 1
        local samples = self.samples
        local step_size = samples.step

        while curSample ~= lastSample and samples[curSample] <= X do
          intervalStart = intervalStart + step_size
          curSample = curSample + 1
        end
        curSample = curSample - 1

        -- Interpolate to provide an initial guess for T
        local dist = (X - samples[curSample]) / (samples[curSample + 1] - samples[curSample])
        local Tguess = intervalStart + dist * step_size

        local c1 = (1.0 - 3.0 * X2 + 3.0 * X1)
        local c2 = (3.0 * X2 - 6.0 * X1)
        local c3 = (3.0 * X1)
        --[[getSlope(Tguess, X1, X2)]]
        local initSlope = 3.0 * c1 * Tguess ^ 2 + 2.0 * c2 * Tguess + c3
        if (initSlope >= self.options.newton_minslope) then
          --[[newtonRaphsonIterate(X, Tguess, X1, X2)]]
          for _ = 1, self.options.newton_iters do
            --[[getSlope(Tguess, X1, X2)]]
            local curSlope = 3.0 * c1 * Tguess ^ 2 + 2.0 * c2 * Tguess + c3
            if (curSlope == 0.0) then break end
            --[[calcBezier(Tguess, X1, X2) - X]]
            local curX = (((c1 * Tguess + c2) * Tguess + c3) * Tguess) - X
            Tguess = Tguess - (curX / curSlope)
          end
          T = Tguess
        elseif (initSlope == 0) then
          T = Tguess
        else
          local A = intervalStart
          local B = intervalStart + step_size
          --[[binarySubdivide(X, A, B, X1, X2)]]
          local curX, curT
          local iter = 0
          while (m_abs(curX) > self.options.subdiv_prec and iter < self.options.subdiv_iters) do
            curT = A + (B - A) * 0.5
            --[[calcBezier(curT, X1, X2) - X]]
            curX = ((((1.0 - 3.0 * X2 + 3.0 * X1) * curT + (3.0 * X2 - 6.0 * X1)) * curT + (3.0 * X1)) * curT) - X
            if curX > 0.0 then B = curT else A = curT end
            iter = iter + 1
          end
          T = curT or (A + (B - A) * 0.5)
        end
        --#end getTForX#
        --[[calcBezier(T, Y1, Y2)]]
        return (((1.0 - 3.0 * Y2 + 3.0 * Y1) * T + (3.0 * Y2 - 6.0 * Y1)) * T + (3.0 * Y1)) * T
      end,
      __index = {
        wrap = function(self) return function(state, data) self(state, data) end end
      },
      type = "Bezier"
    }


    ---Generates a custom bezier curve.
    ---
    ---These are expensive to run so use them sparingly or use low settings.
    ---@param x1 number
    ---@param y1 number
    ---@param x2 number
    ---@param y2 number
    ---@param options? Lib.GS.AnimBlend.BezierOptions
    ---@return Lib.GS.AnimBlend.blendCurve
    function callbackFunction.genBezier(x1, y1, x2, y2, options)
      -- Because some dumbass won't read the instructions...
      ---@diagnostic disable-next-line: undefined-field
      if type(x1) == "table" and x1.done ~= nil then
        error("attempt to use generator 'bezierEasing' as a blend callback.", 2)
      end

      -- Optimization. This may cause an issue if a Bezier object is expected.
      -- If you actually need a Bezier object then don't make a linear bezier lmao.
      if x1 == y1 and x2 == y2 then return easingCurve.linear end

      ---===== Verify options =====---
      local to = type(options)
      if to == "nil" then
        options = {
          newton_iters = default_newton_iters,
          newton_minslope = default_newton_minslope,
          subdiv_prec = default_subdiv_prec,
          subdiv_iters = default_subdiv_iters,
          sample_size = default_sample_size
        }
      elseif to ~= "table" then
        error("bad argument #5 to 'bezierEasing' (table expected, got " .. to .. ")")
      else
        local safe = this.safe
        local oni = options.newton_iters
        if oni == nil then
          options.newton_iters = default_newton_iters
        elseif safe then
          assert(chk.badnum('5["newton_iters"]', "bezierEasing", oni))
        end

        local onm = options.newton_minslope
        if onm == nil then
          options.newton_minslope = default_newton_minslope
        elseif safe then
          assert(chk.badnum('5["newton_minslope"]', "bezierEasing", onm))
        end

        local osp = options.subdiv_prec
        if osp == nil then
          options.subdiv_prec = default_subdiv_prec
        elseif safe then
          assert(chk.badnum('5["subdiv_prec"]', "bezierEasing", osp))
        end

        local osi = options.subdiv_iters
        if osi == nil then
          options.subdiv_iters = default_subdiv_iters
        elseif safe then
          assert(chk.badnum('5["subdiv_iters"]', "bezierEasing", osi))
        end

        local oss = options.sample_size
        if oss == nil then
          options.sample_size = default_sample_size
        elseif safe then
          assert(chk.badnum('5["sample_size"]', "bezierEasing", oss))
        end
      end

      if this.safe then
        chk.badnum(1, "bezierEasing", x1)
        chk.badnum(2, "bezierEasing", y1)
        chk.badnum(3, "bezierEasing", x2)
        chk.badnum(4, "bezierEasing", y2)
      end

      if x1 > 1 or x1 < 0 then
        error("bad argument #1 to 'bezierEasing' (value out of [0, 1] range)", 2)
      end
      if x2 > 1 or x2 < 0 then
        error("bad argument #3 to 'bezierEasing' (value out of [0, 1] range)", 2)
      end

      local samples = {step = 1 / (options.sample_size - 1)}

      ---@type Lib.GS.AnimBlend.bezierCurve
      local obj = setmetatable({
        x1, y1, x2, y2,
        options = options,
        samples = samples
      }, BezierMT)

      local step = samples.step
      local c1 = (1.0 - 3.0 * x2 + 3.0 * x1)
      local c2 = (3.0 * x2 - 6.0 * x1)
      local c3 = (3.0 * x1)
      for i = 0, options.sample_size - 1 do
        local istep = i * step
        --[[calcBezier(istep, X1, X2)]]
        samples[i] = ((c1 * istep + c2) * istep + c3) * istep
      end

      return obj
    end
  end


  ---The default callback used by this library. This is used when no other callback is being used.
  ---@type Lib.GS.AnimBlend.blendCallback
  this.defaultCallback = callbackFunction[("base")]
  ---The default curve used by this library. This is used when no other curve is being used.
  ---@type Lib.GS.AnimBlend.blendCurve
  this.defaultCurve = easingCurve[("linear")]
  this.callback = callbackFunction
  this.curve = easingCurve


  -----===================================== BLENDING LOGIC =====================================-----

  events.TICK:register(function()
    ticker = ticker + 1

    -- Blends stop updating when the player is unloaded. Force blends to end early if this happens.
    if not player:isLoaded() then
      for anim in pairs(blending) do
        local data = animData[anim]
        local state = data.state

        -- Paused blends don't do anything anyways so this isn't an issue.
        if not state.paused then
          mt_bypass:push(anim)
          local cbs = state.callbackState
          cbs.time = cbs.max
          cbs.rawProgress = 1
          cbs.progress = state.curve(1)
          cbs.done = true

          -- Do final callback.
          for _, cb in ipairs(state.callbacks) do cb(cbs, data) end
          blending[anim] = nil
          anim:setPlaying(state.starting)
          anim:setBlend(data.blend)
          mt_bypass:pop(anim)
        end
      end
    end
  end, "GSAnimBlend:Tick_TimeTicker")

  events.RENDER:register(function(delta, ctx)
    if not allowed_contexts[ctx] or (delta == last_delta and ticker == 0) then return end
    local elapsed_time = ticker + (delta - last_delta)
    ticker = 0
    for anim in pairs(blending) do
      -- Every frame, update time and progress, then call the callback.
      local data = animData[anim]
      local state = data.state
      if not state.paused then
        if state.delay > 0 then state.delay = state.delay - elapsed_time end
        if state.delay <= 0 then
          local cbs = state.callbackState
          state.time = state.time + elapsed_time
          cbs.max = state.max or (state.starting and data.blendTimeIn or data.blendTimeOut)
          if not state.from then
            cbs.from = data.blendSane
            cbs.to = state.to
          elseif not state.to then
            cbs.from = state.from
            cbs.to = data.blendSane
          else
            cbs.from = state.from
            cbs.to = state.to
          end

          mt_bypass:push(anim)
          -- When a blend stops, update all info to signal it has stopped.
          if (state.time >= cbs.max) or (anim:getPlayState() == "STOPPED") then
            cbs.time = cbs.max
            cbs.rawProgress = 1
            cbs.progress = state.curve(1)
            cbs.done = true

            -- Do final callback.
            for _, cb in ipairs(state.callbacks) do cb(cbs, data) end
            blending[anim] = nil
            anim:setPlaying(state.starting)
            anim:setBlend(data.blend)
          else
            cbs.time = state.time
            cbs.rawProgress = cbs.time / cbs.max
            cbs.progress = state.curve(cbs.rawProgress)
            for _, cb in ipairs(state.callbacks) do cb(cbs, data) end
          end
          mt_bypass:pop(anim)
        end
      end
    end
    last_delta = delta
  end, "GSAnimBlend:Render_UpdateBlendStates")


  -----================================ METATABLE MODIFICATIONS =================================-----

  ---===== FIELDS =====---

  local animationGetters = {}
  local animationSetters = {}

  function animationGetters:blendCallback()
    if this.safe then assert(chk.badarg(1, "__index", self, "Animation")) end
    return animData[self].callbacks[0]
  end
  function animationSetters:blendCallback(value)
    if this.safe then
      assert(chk.badarg(1, "__newindex", self, "Animation"))
      assert(chk.badarg(3, "__newindex", value, "function", true))
    end

    local data = animData[self]
    data.callbacks[0] = value

    local callbacks_cache = {}
    for k, v in pairs(data.callbacksCache) do callbacks_cache[k] = v end
    callbacks_cache[callbacks_cache.priority_0] = value
    callbacks_cache.use_default = value == nil
    data.callbacksCache = callbacks_cache
    return self
  end


  ---===== METHODS =====---

  local animationMethods = {}

  function animationMethods:newCode(time, code)
    local data = animData[self]
    if time == 0 then
      ---@diagnostic disable-next-line: redundant-parameter
      data.startFunc = load(code, ("animations.%s.%s"):format(data.model, self.name))
      data.startSource = code
    elseif time == data.length then
      ---@diagnostic disable-next-line: redundant-parameter
      data.endFunc = load(code, ("animations.%s.%s"):format(data.model, self.name))
      data.endSource = code
    else
      return animNewCode(self, time, code)
    end

    return self
  end

  function animationMethods:play(instant)
    if this.safe then assert(chk.badarg(1, "play", self, "Animation")) end

    if blending[self] then
      if instant then
        this.stopBlend(self, true)
        return self
      end

      local data = animData[self]
      local state = data.state
      if state.paused then
        state.paused = false
        return self
      elseif state.starting then
        return self
      end

      animStop(self)
      local time = data.blendTimeIn * state.callbackState.progress
      this.blend(self, time, animGetBlend(self), nil, true)
      return self
    elseif instant or animData[self].blendTimeIn == 0 or animGetPlayState(self) ~= "STOPPED" then
      return animPlay(self)
    end

    this.blend(self, nil, 0, nil, true)
    return self
  end

  function animationMethods:stop(instant)
    if this.safe then assert(chk.badarg(1, "stop", self, "Animation")) end

    if blending[self] then
      if instant then
        this.stopBlend(self, false)
        return self
      end

      local data = animData[self]
      local state = data.state
      if not state.starting then
        return self
      end

      local time = data.blendTimeOut * state.callbackState.progress
      this.blend(self, time, animGetBlend(self), 0, false)
      return self
    elseif instant or animData[self].blendTimeOut == 0 or animGetPlayState(self) == "STOPPED" then
      return animStop(self)
    end

    this.blend(self, nil, nil, 0, false)
    return self
  end

  function animationMethods:pause()
    if this.safe then assert(chk.badarg(1, "pause", self, "Animation")) end

    if blending[self] then
      animData[self].state.paused = true
      return self
    end

    return animPause(self)
  end

  function animationMethods:restart(blend)
    if this.safe then assert(chk.badarg(1, "restart", self, "Animation")) end

    if blend and blending[self] then
      local data = animData[self]
      local state = data.state

      animStop(self)
      local time = data.blendTimeIn * state.callbackState.progress
      this.blend(self, time, animGetBlend(self), nil, true)
      return self
    end

    this.stopBlend(self, false)
    return animRestart(self)
  end


  ---===== GETTERS =====---

  function animationMethods:getBlendTime()
    if this.safe then assert(chk.badarg(1, "getBlendTime", self, "Animation")) end
    local data = animData[self]
    return data.blendTimeIn, data.blendTimeOut
  end

  function animationMethods:getBlendCallback(priority)
    if this.safe then
      assert(chk.badarg(1, "getBlendCallback", self, "Animation"))
      assert(chk.badnum(2, "getBlendCallback", priority, true))
    end
    return animData[self].callbacks[priority or 0]
  end

  function animationMethods:isBlending()
    if this.safe then assert(chk.badarg(1, "isBlending", self, "Animation")) end
    return not not blending[self]
  end

  function animationMethods:getBlend()
    if this.safe then assert(chk.badarg(1, "getBlend", self, "Animation")) end
    return animData[self].blend
  end

  function animationMethods:getPlayState()
    if this.safe then assert(chk.badarg(1, "getPlayState", self, "Animation")) end
    return blending[self] and (animData[self].state.paused and "PAUSED" or "PLAYING") or animGetPlayState(self)
  end

  function animationMethods:getTime()
    if this.safe then assert(chk.badarg(1, "getPlayState", self, "Animation")) end
    local state = animData[self].state
    return blending[self] and state.delay > 0 and (state.delay / -20) or animGetTime(self)
  end

  function animationMethods:isPlaying()
    if this.safe then assert(chk.badarg(1, "isPlaying", self, "Animation")) end
    return blending[self] and not animData[self].state.paused or animIsPlaying(self)
  end

  function animationMethods:isPaused()
    if this.safe then assert(chk.badarg(1, "isPaused", self, "Animation")) end
    return (not blending[self] or animData[self].state.paused) and animIsPaused(self)
  end


  ---===== SETTERS =====---

  function animationMethods:setBlendTime(time_in, time_out)
    if time_in == nil then time_in = 0 end
    if this.safe then
      assert(chk.badarg(1, "setBlendTime", self, "Animation"))
      assert(chk.badnum(2, "setBlendTime", time_in))
      assert(chk.badnum(3, "setBlendTime", time_out, true))
    end

    local data = animData[self]
    data["EZAnims$hasBlendTime"] = true
    data.blendTimeIn = m_max(time_in, 0)
    data.blendTimeOut = m_max(time_out or time_in, 0)
    return self
  end

  function animationMethods:setOnBlend(func, priority)
    if this.safe then
      assert(chk.badarg(1, "setOnBlend", self, "Animation"))
      assert(chk.badarg(2, "setOnBlend", func, "function", true))
      assert(chk.badarg(3, "setOnBlend", priority, "number", true))
    end

    local data = animData[self]
    priority = priority or 0

    local old = data.callbacks[priority or 0]
    if func == old then return self end

    if priority == 0 then
      data.callbacks[0] = func

      local callbacks_cache = {}
      for k, v in pairs(data.callbacksCache) do callbacks_cache[k] = v end
      callbacks_cache[callbacks_cache.priority_0] = func
      callbacks_cache.use_default = func == nil
      data.callbacksCache = callbacks_cache
      return self
    end

    local callbacks = data.callbacks
    callbacks[priority] = func

    local callbacks_cache = {}
    local use_default = true
    for i in pairs(callbacks) do
      if i == 0 then use_default = false end
      callbacks_cache[#callbacks_cache+1] = i
    end

    if use_default then callbacks_cache[#callbacks_cache+1] = 0 end
    table.sort(callbacks_cache)

    for i, v in ipairs(callbacks_cache) do
      if v == 0 then callbacks_cache.priority_0 = i end
      callbacks_cache[i] = callbacks[v]
    end

    callbacks_cache.use_default = use_default
    data.callbacksCache = callbacks_cache

    return self
  end

  function animationMethods:setBlendCurve(curve)
    local curve_isstr = type(curve) == "string"

    if this.safe then
      assert(chk.badarg(1, "setBlendCurve", self, "Animation"))
      if not curve_isstr then
        assert(chk.badarg(2, "setBlendCurve", curve, "function", true))
      end
    end

    if curve_isstr then
      curve = easingCurve[curve]
        or error("bad argument #2 of 'setBlendCurve' ('" .. curve .. "' is not a valid curve)", 2)
    end
    animData[self].curve = curve
    return self
  end

  function animationMethods:setBlend(weight)
    if weight == nil then weight = 0 end
    if this.safe then
      assert(chk.badarg(1, "setBlend", self, "Animation"))
      assert(chk.badarg(2, "setBlend", weight, "number"))
    end

    local data = animData[self]
    data.blend = weight
    data.blendSane = makeSane(weight, 0)
    return blending[self] and self or animBlend(self, weight)
  end

  function animationMethods:setLength(len)
    if len == nil then len = 0 end
    if len == self:getLength() then return animLength(self, len) end
    if this.safe then
      assert(chk.badarg(1, "setLength", self, "Animation"))
      assert(chk.badarg(2, "setLength", len, "number"))
    end

    local data = animData[self]
    if data.endSource or (data.length and data.length ~= 0) then
      animNewCode(self, data.length, data.endSource or "")
      data.endFunc = nil
      data.endSource = nil
    end

    local lenSane = makeSane(len, false)

    if data.length == 0 then
      animNewCode(self, 0, blendCommand:format(data.triggerId, "true"))
    end

    if lenSane then
      if lenSane == 0 then
        animNewCode(self, 0, blendCommand:format(data.triggerId, "nil"))
      else
        animNewCode(self, lenSane, blendCommand:format(data.triggerId, "false"))
      end
    end
    data.length = lenSane

    return animLength(self, len)
  end

  function animationMethods:setPlaying(state, instant)
    if this.safe then assert(chk.badarg(1, "setPlaying", self, "Animation")) end
    return state and self:play(instant) or self:stop(instant)
  end

  function animationMethods:setTime(time)
    if this.safe then
      assert(chk.badarg(1, "setTime", self, "Animation"))
      assert(chk.badarg(2, "setTime", time, "number"))
    end

    if blending[self] then animData[self].state.delay = 0 end
    return animTime(self, time)
  end


  ---===== CHAINED =====---

  animationMethods.blendTime = animationMethods.setBlendTime
  animationMethods.onBlend = animationMethods.setOnBlend
  animationMethods.blendCurve = animationMethods.setBlendCurve
  animationMethods.blend = animationMethods.setBlend
  animationMethods.length = animationMethods.setLength
  animationMethods.playing = animationMethods.setPlaying


  ---===== METAMETHODS =====---

  function animation_mt:__index(key)
    if mt_bypass:check(self) then
      local value = _animationIndex(self, key)
      if value ~= nil then return value end
    end

    if animationGetters[key] then
      return animationGetters[key](self)
    elseif animationMethods[key] then
      return animationMethods[key]
    else
      return _animationIndex(self, key)
    end
  end

  function animation_mt:__newindex(key, value)
    if animationSetters[key] then
      animationSetters[key](self, value)
    else
      _animationNewIndex(self, key, value)
    end
  end


  -----============================== ANIMATION API MODIFICATIONS ===============================-----

  if animationapi_mt then
    local apiMethods = {}
    local PAST = cmp("0.1.4") ~= 1

    function apiMethods:getPlaying(hold, ignore_blending)
      if this.safe then assert(chk.badarg(1, "getPlaying", self, "AnimationAPI")) end
      if ignore_blending then return animapiGetPlaying(self, hold) end
      if PAST then hold = false end

      local anims = {}
      for _, anim in ipairs(self:getAnimations()) do
        if anim:isPlaying() or (hold and anim:isHolding()) then anims[#anims+1] = anim end
      end

      return anims
    end

    function animationapi_mt:__index(key)
      return apiMethods[key] or _animationapiIndex(self, key)
    end
  end

  return setmetatable(this, thismt)
end)

if s then
  return this
else -- This is *all* error handling.
  ---@cast this string
  local e_msg, e_stack = string.match(this, "^(.-)\nstack traceback:\n(.*)$")

  -- Modify Stack
  local stack_lines = {}
  local skip_next
  for line in e_stack:gmatch("[ \t]*([^\n]+)") do
    -- If the level is not a Java level, keep it.
    if not line:match("^%[Java]:") then
      if not skip_next then
        stack_lines[#stack_lines+1] = ("    §4" .. line)
      else
        skip_next = false
      end
    elseif line:match("in function 'pcall'") then
      -- If the level *is* a Java level and it contains the pcall, remove both it and the level above.
      if #stack_lines > 0 then
        stack_lines[#stack_lines] = stack_lines[#stack_lines]:gsub("in function %b<>", "in protected chunk")
      end
      skip_next = true
    end
  end

  local extra_reason = ""

  local check = 0
  if FIG[1] then
    check = cmp(FIG[1])
    if check == -1 then
      extra_reason = ("\n§7§oYour Figura version (%s) is below the recommended minimum of %s§r"):format(CLIENT_VERSION, FIG[1])
    elseif not check then
      check = nil
    end
  end
  if check and FIG[2] then
    check = cmp(FIG[2])
    if check == 1 then
      extra_reason = ("\n§7§oYour Figura version (%s) is above the recommended maximum of %s§r"):format(CLIENT_VERSION, FIG[2])
    elseif not check then
      check = nil
    end
  end

  if not check then extra_reason = ("\n§7§oYour Figura version (%s) is not valid!§r"):format(CLIENT_VERSION) end

  error(
    (
      "'%s' failed to load\z
       \n§7INFO: %s v%s | %s§c%s\z
       \ncaused by:\z
       \n  §4%s\z
       \n  stack traceback:\z
       \n%s§c"
    ):format(
      ID,
      ID, VER, CLIENT_VERSION, extra_reason,
      e_msg:gsub("\n", "\n  §4"),
      table.concat(stack_lines, "\n")
    ),
    2
  )
end

--|==================================================================================================================|--
--|=====|| DOCUMENTATION ||==========================================================================================|--
--||=:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:=:==:=:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:==:=||--

---@diagnostic disable: duplicate-set-field, duplicate-doc-field, duplicate-doc-alias
---@diagnostic disable: missing-return, unused-local, lowercase-global, unreachable-code

---@class Lib.GS.AnimBlend.AnimData
---The blending-in time of this animation in ticks.
---@field blendTimeIn number
---The blending-out time of this animation in ticks.
---@field blendTimeOut number
---The faked blend weight value of this animation.
---@field blend number
---The preferred blend weight that blending will use.
---@field blendSane number
---Where in the timeline the stop instruction is placed.  
---If this is `false`, there is no stop instruction due to length limits.
---@field length number|false
---The id for this animation's blend trigger
---@field triggerId integer
---The name of the model this animation belongs to.
---@field model string
---The original instruction keyframe at the start of the animation.
---@field startFunc? function
---The original instruction keyframe at the end of the animation.
---@field endFunc? function
---The original string source of the instruction keyframe at the start of the animation.
---@field startSource? string
---The original string source of the instruction keyframe at the end of the animation.
---@field endSource? string
---The callback functions this animation will call every frame while it is blending and one final
---time when blending finishes.
---@field callbacks {[integer]: Lib.GS.AnimBlend.blendCallback}
---The cached order of this animation's callbacks. Don't touch this.
---@field callbacksCache {[integer]: Lib.GS.AnimBlend.blendCallback, priority_0: integer, use_default: boolean}
---The curve that the blending progress is modified with.
---@field curve? Lib.GS.AnimBlend.blendCurve
---The active blend state.
---@field state? Lib.GS.AnimBlend.BlendState

---@class Lib.GS.AnimBlend.BlendState
---The amount of time this blend has been running for in ticks.
---@field time number
---The maximum time this blend will run in ticks.
---@field max number|false
---The starting blend weight.
---@field from number|false
---The ending blend weight.
---@field to number|false
---The callbacks to call each blending frame.
---@field callbacks {[integer]: Lib.GS.AnimBlend.blendCallback, priority_0: integer}
---The curve that the blending progress is modified with.
---@field curve? Lib.GS.AnimBlend.blendCurve
---The state proxy used in the blend callback function.
---@field callbackState Lib.GS.AnimBlend.CallbackState
---Determines if this blend is paused.
---@field paused boolean
---Determines if this blend is starting or ending an animation.
---@field starting boolean
---Determines how long a delay waits before playing.
---@field delay number

---@class Lib.GS.AnimBlend.CallbackState
---The animation this callback is acting on.
---@field anim Animation
---The amount of time this blend has been running for in ticks.
---@field time number
---The maximum time this blend will run in ticks.
---@field max number
---The progress as a percentage modified by the current curve.  
---This can be above 1 or below 0 if the curve results in it.
---@field progress number
---The progress as a percentage without any curve modifications.
---@field rawProgress number
---The starting blend weight.
---@field from number
---The ending blend weight.
---@field to number
---Determines if this blend is starting or ending an animation.
---@field starting boolean
---Determines if this blend is finishing up.
---@field done boolean

---@class Lib.GS.AnimBlend.BezierOptions
---How many time to use the Newton-Raphson method to approximate.  
---Higher numbers create more accurate approximations at the cost of instructions.
---
---The default value is `4`.
---@field newton_iters? integer
---The minimum slope required to attempt to use the Newton-Raphson method.  
---Lower numbers cause smaller slopes to be approximated at the cost of instructions.
---
---The default value is `0.001`.
---@field newton_minslope? number
---The most precision that subdivision will allow before stopping early.  
---Lower numbers cause subdivision to allow more precision at the cost of instructions.
---
---The default value is `0.0000001`.
---@field subdiv_prec? number
---The maximum amount of times that subdivision will be performed.  
---Higher numbers cause more subdivision to happen at the cost of instructions.
---
---The default value is `10`.
---@field subdiv_iters? integer
---The amount of samples to gather from the bezier curve.  
---Higher numbers gather more samples at the cost of more instructions when creating the curve.  
---Lower numbers gather less samples at the cost of more instructions when blending with the curve.
---
---The default value is `11`.
---@field sample_size? integer

---@class Lib.GS.AnimBlend.Bezier: function
---@overload fun(progress: number): number
---The X1 value.
---@field [1] number
---The Y1 value.
---@field [2] number
---The X2 value.
---@field [3] number
---The Y2 value.
---@field [4] number
---The options used to make this bezier.
---@field options Lib.GS.AnimBlend.BezierOptions
---The samples gathered from this bezier.
---@field samples {step: number, [integer]: number}

---@class Lib.GS.AnimBlend.tlKeyframe
---The progress this keyframe starts at in the range [0, 1).
---
---If the first keyframe does not start at `0`, an error will be thrown.  
---A keyframe at or after time `1` will never run as completing the blend will be preferred.
---@field time number
---The starting adjusted-progress of this keyframe.  
---Despite the name of this option, it does not need to be smaller than `max`.
---
---All keyframes get an adjusted-progress which starts when the keyframe starts and ends when the next keyframe (or the
---end of the timeline) is hit.
---
---The default value is `0`.
---@field min? number
---The ending adjusted-progress of this keyframe.  
---Despite the name of this option, it does not need to be bigger than `min`.
---
---All keyframes get an adjusted-progress which starts when the keyframe starts and ends when the next keyframe (or the
---end of the timeline) is hit.
---
---The default value is `1`.
---@field max? number
---The blending callback to use for this entire keyframe.  
---The adjusted-progress is given to this callback as it runs.
---
---If `nil` is given, the default callback is used.
---
---Note: Blending callbacks called by this function will **never** call cleanup code. Care should be taken to make sure
---this does not break anything.
---@field callback? Lib.GS.AnimBlend.blendCallback
---The easing curve to use for this entire keyframe.  
---The adjusted-progress is given to this callback as it runs.
---
---If a string is given instead of a callback, it is treated as the name of a curve found in
---`<GSAnimBlend>.callbackCurve`.  
---If `nil` is given, the default curve is used.
---@field curve? Lib.GS.AnimBlend.blendCurve | Lib.GS.AnimBlend.curve

---@alias Lib.GS.AnimBlend.blendCallback
---| fun(state: Lib.GS.AnimBlend.CallbackState, data: Lib.GS.AnimBlend.AnimData)

---@alias Lib.GS.AnimBlend.blendCurve fun(progress: number): number

---@alias Lib.GS.AnimBlend.bezierCurve Lib.GS.AnimBlend.Bezier | Lib.GS.AnimBlend.blendCurve

---@alias Lib.GS.AnimBlend.timeline Lib.GS.AnimBlend.tlKeyframe[]

---@alias Lib.GS.AnimBlend.curve
---| "linear"           # The default blending curve. Goes from 0 to 1 without any fancy stuff.
---| "smoothStep"       # A more performant but less accurate version of easeInOutSine.
---| "easeInSine"       # [Learn More...](https://easings.net/#easeInSine)
---| "easeOutSine"      # [Learn More...](https://easings.net/#easeOutSine)
---| "easeInOutSine"    # [Learn More...](https://easings.net/#easeInOutSine)
---| "easeInQuad"       # [Learn More...](https://easings.net/#easeInQuad)
---| "easeOutQuad"      # [Learn More...](https://easings.net/#easeOutQuad)
---| "easeInOutQuad"    # [Learn More...](https://easings.net/#easeInOutQuad)
---| "easeInCubic"      # [Learn More...](https://easings.net/#easeInCubic)
---| "easeOutCubic"     # [Learn More...](https://easings.net/#easeOutCubic)
---| "easeInOutCubic"   # [Learn More...](https://easings.net/#easeInOutCubic)
---| "easeInQuart"      # [Learn More...](https://easings.net/#easeInQuart)
---| "easeOutQuart"     # [Learn More...](https://easings.net/#easeOutQuart)
---| "easeInOutQuart"   # [Learn More...](https://easings.net/#easeInOutQuart)
---| "easeInQuint"      # [Learn More...](https://easings.net/#easeInQuint)
---| "easeOutQuint"     # [Learn More...](https://easings.net/#easeOutQuint)
---| "easeInOutQuint"   # [Learn More...](https://easings.net/#easeInOutQuint)
---| "easeInExpo"       # [Learn More...](https://easings.net/#easeInExpo)
---| "easeOutExpo"      # [Learn More...](https://easings.net/#easeOutExpo)
---| "easeInOutExpo"    # [Learn More...](https://easings.net/#easeInOutExpo)
---| "easeInCirc"       # [Learn More...](https://easings.net/#easeInCirc)
---| "easeOutCirc"      # [Learn More...](https://easings.net/#easeOutCirc)
---| "easeInOutCirc"    # [Learn More...](https://easings.net/#easeInOutCirc)
---| "easeInBack"       # [Learn More...](https://easings.net/#easeInBack)
---| "easeOutBack"      # [Learn More...](https://easings.net/#easeOutBack)
---| "easeInOutBack"    # [Learn More...](https://easings.net/#easeInOutBack)
---| "easeInElastic"    # [Learn More...](https://easings.net/#easeInElastic)
---| "easeOutElastic"   # [Learn More...](https://easings.net/#easeOutElastic)
---| "easeInOutElastic" # [Learn More...](https://easings.net/#easeInOutElastic)
---| "easeInBounce"     # [Learn More...](https://easings.net/#easeInBounce)
---| "easeOutBounce"    # [Learn More...](https://easings.net/#easeOutBounce)
---| "easeInOutBounce"  # [Learn More...](https://easings.net/#easeInOutBounce)


---@class Animation
---#### [GS AnimBlend Library]
---The callback with priority 0 that should be called every frame while the animation is blending.
---
---This allows adding custom behavior to the blending feature.
---
---If this is `nil`, it will default to the library's base callback.
---@field blendCallback? Lib.GS.AnimBlend.blendCallback
local Animation


---===== METHODS =====---

---#### [GS AnimBlend Library]
---Starts or resumes this animation. Does nothing if the animation is already playing.  
---If `instant` is set, no blending will occur.
---
---If `instant` is `nil`, it will default to `false`.
---@generic self
---@param self self
---@param instant? boolean
---@return self
function Animation:play(instant) end

---#### [GS AnimBlend Library]
---Starts this animation from the beginning, even if it is currently paused or playing.
---
---If `blend` is set, it will also restart with a blend.
---@generic self
---@param self self
---@param blend? boolean
---@return self
function Animation:restart(blend) end

---#### [GS AnimBlend Library]
---Stops this animation.  
---If `instant` is set, no blending will occur.
---
---If `instant` is `nil`, it will default to `false`.
---@generic self
---@param self self
---@param instant? boolean
---@return self
function Animation:stop(instant) end


---===== GETTERS =====---

---#### [GS AnimBlend Library]
---Gets the blending times of this animation in ticks.
---@return number, number
function Animation:getBlendTime() end

---#### [GS AnimBlend Library]
---Gets the blending callback at the given priority in this animation.
---
---If `priority` is `nil`, it will default to `0`.
---@param priority? integer
---@return Lib.GS.AnimBlend.blendCallback?
function Animation:getBlendCallback(priority) end

---#### [GS AnimBlend Library]
---Gets if this animation is currently blending.
---@return boolean
function Animation:isBlending() end


---===== SETTERS =====---

---#### [GS AnimBlend Library]
---Sets the blending time of this animation in ticks.
---@generic self
---@param self self
---@param time? number
---@return self
function Animation:setBlendTime(time) end

---#### [GS AnimBlend Library]
---Sets the blending-in and blending-out times of this animation in ticks.
---@generic self
---@param self self
---@param time_in? number
---@param time_out? number
---@return self
function Animation:setBlendTime(time_in, time_out) end

---#### [GS AnimBlend Library]
---Sets a blending callback at the given priority in this animation.  
---Higher priorities run later. Only one callback may have a given priority in an animation.
---
---If `priority` is `nil`, it will default to `0`.
---@generic self
---@param self self
---@param func? Lib.GS.AnimBlend.blendCallback
---@param priority? integer
---@return self
function Animation:setOnBlend(func, priority) end

---#### [GS AnimBlend Library]
---Sets the easing curve of this animation.
---@generic self
---@param self self
---@param curve? Lib.GS.AnimBlend.blendCurve | Lib.GS.AnimBlend.curve
---@return self
function Animation:setBlendCurve(curve) end

---#### [GS AnimBlend Library]
---Sets if this animation is currently playing.  
---If `instant` is set, no blending will occur.
---
---If `state` or `instant` are `nil`, they will default to `false`.
---@generic self
---@param self self
---@param state? boolean
---@param instant? boolean
---@return self
function Animation:setPlaying(state, instant) end


---===== CHAINED =====---

---#### [GS AnimBlend Library]
---Sets the blending time of this animation in ticks.
---@generic self
---@param self self
---@param time? number
---@return self
function Animation:blendTime(time) end

---#### [GS AnimBlend Library]
---Sets the blending-in and blending-out times of this animation in ticks.
---@generic self
---@param self self
---@param time_in? number
---@param time_out? number
---@return self
function Animation:blendTime(time_in, time_out) end

---#### [GS AnimBlend Library]
---Sets a blending callback at the given priority in this animation.  
---Higher priorities run later. Only one callback may have a given priority in an animation.
---
---If `priority` is `nil`, it will default to `0`.
---@generic self
---@param self self
---@param func? Lib.GS.AnimBlend.blendCallback
---@param priority? integer
---@return self
function Animation:onBlend(func, priority) end

---#### [GS AnimBlend Library]
---Sets the easing curve of this animation.
---@generic self
---@param self self
---@param curve? Lib.GS.AnimBlend.blendCurve | Lib.GS.AnimBlend.curve
---@return self
---@diagnostic disable-next-line: assign-type-mismatch
function Animation:blendCurve(curve) end

---#### [GS AnimBlend Library]
---Sets if this animation is currently playing.  
---If `instant` is set, no blending will occur.
---
---If `state` or `instant` are `nil`, they will default to `false`.
---@generic self
---@param self self
---@param state? boolean
---@param instant? boolean
---@return self
function Animation:playing(state, instant) end


---@class AnimationAPI
local AnimationAPI


---===== GETTERS =====---

---#### [GS AnimBlend Library] (0.1.5+)
---Gets an array of every playing animation.  
---**`(0.1.5+ only)`** If `hold` is set, HOLDING animations are included.
---
---Set `ignore_blending` to ignore animations that are currently blending.
---@param hold? boolean
---@param ignore_blending? boolean
---@return Animation[]
function AnimationAPI:getPlaying(hold, ignore_blending) end
