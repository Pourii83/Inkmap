-- Inkmap: Leatrix Maps style world map enhancements for the 1.12 client
-- (OctoWoW / Turtle WoW). Written for Lua 5.0: no '#', no 'select',
-- event handlers use the 'this', 'event' and 'arg1' globals.

Inkmap = {
  version = "1.0.0",
  modules = {},
}

local Inkmap = Inkmap

Inkmap.defaults = {
  -- windowed map
  window = true,
  locked = false,
  scale = 0.8,
  alpha = 1.0,
  fade = true,
  fadeAlpha = 0.4,
  fadeAway = true,
  awayAlpha = 0.5,
  autoZone = true,
  hideControls = true,
  zoom = true,
  -- unexplored areas
  reveal = true,
  revealTint = true,
  tint = { r = 0.6, g = 0.8, b = 1.0, a = 1.0 },
  overlayData = "auto", -- "auto", "turtle" or "vanilla"
  -- extras
  coords = true,
  zoneLevels = true,
  classIcons = true,
  minimap = true,
  minimapAngle = 200,
}

function Inkmap:Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffInkmap|r: " .. tostring(msg))
end

function Inkmap:Clamp(value, min, max)
  if value < min then return min end
  if value > max then return max end
  return value
end

-- runs 'func' after the frame's existing script handler
function Inkmap:HookScript(frame, script, func)
  local prev = frame:GetScript(script)
  frame:SetScript(script, function(a1, a2, a3, a4, a5, a6, a7, a8, a9)
    if prev then prev(a1, a2, a3, a4, a5, a6, a7, a8, a9) end
    func(a1, a2, a3, a4, a5, a6, a7, a8, a9)
  end)
end

-- modules are tables with optional Init() and Refresh() methods
function Inkmap:RegisterModule(name, module)
  module.name = name
  table.insert(self.modules, module)
  return module
end

function Inkmap:Refresh()
  for _, module in ipairs(self.modules) do
    if module.Refresh then module:Refresh() end
  end
end

-- other map addons that replace the same parts of the world map
function Inkmap:FindConflict()
  if Cartographer then return "Cartographer" end
  if METAMAP_TITLE then return "MetaMap" end
  if pfUI and pfUI.map then return "pfUI (world map module)" end
  return nil
end

local function CopyDefaults(src, dst)
  for k, v in pairs(src) do
    if type(v) == "table" then
      if type(dst[k]) ~= "table" then dst[k] = {} end
      CopyDefaults(v, dst[k])
    elseif dst[k] == nil then
      dst[k] = v
    end
  end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" and arg1 == "Inkmap" then
    InkmapDB = InkmapDB or {}
    -- 1.0 saved the old default; move it to the new one unless it was changed
    if not InkmapDB.dbVersion and InkmapDB.awayAlpha == 0.75 then InkmapDB.awayAlpha = 0.5 end
    InkmapDB.dbVersion = 2
    CopyDefaults(Inkmap.defaults, InkmapDB)
    Inkmap.db = InkmapDB
  elseif event == "PLAYER_ENTERING_WORLD" and not Inkmap.initialized then
    Inkmap.initialized = true
    Inkmap.conflict = Inkmap:FindConflict()
    if Inkmap.conflict then
      Inkmap:Print("map window and unexplored areas are disabled because " .. Inkmap.conflict .. " is loaded.")
    end
    for _, module in ipairs(Inkmap.modules) do
      if module.Init then module:Init() end
    end
  end
end)

local function ShowHelp()
  Inkmap:Print("v" .. Inkmap.version .. " commands:")
  DEFAULT_CHAT_FRAME:AddMessage("  /inkmap - open the options window")
  DEFAULT_CHAT_FRAME:AddMessage("  /inkmap reset - reset map position, scale and opacity")
  DEFAULT_CHAT_FRAME:AddMessage("  /inkmap lock - lock or unlock the map position")
  DEFAULT_CHAT_FRAME:AddMessage("  /inkmap data auto|turtle|vanilla - unexplored area data set")
  DEFAULT_CHAT_FRAME:AddMessage("  Mouse wheel on the map: zoom, drag: pan while zoomed")
  DEFAULT_CHAT_FRAME:AddMessage("  Ctrl + mouse wheel on the map: scale, Shift + mouse wheel: opacity")
end

SLASH_INKMAP1 = "/inkmap"
SLASH_INKMAP2 = "/ink"
SlashCmdList["INKMAP"] = function(msg)
  local _, _, cmd, rest = string.find(string.lower(msg or ""), "^%s*(%S*)%s*(.-)%s*$")
  local db = Inkmap.db

  if cmd == "" then
    Inkmap.options:Toggle()
  elseif cmd == "reset" then
    Inkmap.window:Reset()
    Inkmap:Print("map position, scale and opacity have been reset.")
  elseif cmd == "lock" then
    db.locked = not db.locked
    Inkmap:Print(db.locked and "map locked." or "map unlocked.")
    Inkmap:Refresh()
  elseif cmd == "data" and (rest == "auto" or rest == "turtle" or rest == "vanilla") then
    db.overlayData = rest
    Inkmap:Print("unexplored area data: " .. rest)
    Inkmap:Refresh()
  else
    ShowHelp()
  end
end
