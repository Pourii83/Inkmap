-- Shows party and raid members on the world map (and the battlefield
-- minimap) as small circles in their class color.

local Inkmap = Inkmap
local M = Inkmap:RegisterModule("classicons", {})

local CIRCLE = "Interface\\AddOns\\Inkmap\\Media\\Circle"
local UPDATE_INTERVAL = 0.2
local NUM_PARTY, NUM_RAID = 4, 40

-- every map that shows unit icons: { prefix, original icon texture }
M.maps = {}

local function GetUnit(frame, kind, index)
  return frame.unit or (kind == "Party" and "party" .. index or "raid" .. index)
end

local function ColorIcon(frame, unit, enabled, original)
  local icon = getglobal(frame:GetName() .. "Icon")
  if not icon then return end

  local _, class = UnitClass(unit)
  local color = class and RAID_CLASS_COLORS[class]
  if enabled and color then
    icon:SetTexture(CIRCLE)
    icon:SetVertexColor(color.r, color.g, color.b, 1)
  elseif original then
    icon:SetTexture(original)
    icon:SetVertexColor(1, 1, 1, 1)
  end
end

function M:UpdateMap(map)
  local enabled = Inkmap.db.classIcons
  -- a disabled map only needs restoring once
  if not enabled and not map.colored then return end
  map.colored = enabled

  local kinds = { Party = NUM_PARTY, Raid = NUM_RAID }
  for kind, count in pairs(kinds) do
    for i = 1, count do
      local frame = getglobal(map.prefix .. kind .. i)
      if frame and (frame:IsVisible() or not enabled) then
        -- battleground team positions carry a name but a stale unit
        local known = enabled and not frame.name
        ColorIcon(frame, GetUnit(frame, kind, i), known, map.original[kind])
      end
    end
  end
end

-- remembers the default icon texture and colors the map after each update
function M:AddMap(prefix, updateFrame)
  local party, raid = getglobal(prefix .. "Party1Icon"), getglobal(prefix .. "Raid1Icon")
  if not party and not raid then return end

  local map = {
    prefix = prefix,
    original = {
      Party = party and party:GetTexture(),
      Raid = raid and raid:GetTexture(),
    },
    elapsed = 0,
  }
  table.insert(self.maps, map)

  Inkmap:HookScript(updateFrame, "OnUpdate", function()
    map.elapsed = map.elapsed + (arg1 or 0)
    if map.elapsed < UPDATE_INTERVAL then return end
    map.elapsed = 0
    M:UpdateMap(map)
  end)
end

function M:Refresh()
  for _, map in ipairs(self.maps) do
    map.elapsed = UPDATE_INTERVAL
    self:UpdateMap(map)
  end
end

function M:Init()
  self:AddMap("WorldMap", WorldMapButton)

  -- the battlefield minimap is load on demand
  local function AddBattlefieldMap()
    if self.battlefield or not BattlefieldMinimap then return end
    self.battlefield = true
    self:AddMap("BattlefieldMinimap", BattlefieldMinimap)
  end
  AddBattlefieldMap()

  local watcher = CreateFrame("Frame")
  watcher:RegisterEvent("ADDON_LOADED")
  watcher:SetScript("OnEvent", function()
    if arg1 == "Blizzard_BattlefieldMinimap" then AddBattlefieldMap() end
  end)
end
