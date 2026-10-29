-- Appends the zone level range, colored by difficulty, to the area name
-- the world map shows while hovering a zone.

local Inkmap = Inkmap
local M = Inkmap:RegisterModule("zonelevels", {})

local function LevelColor(min, max)
  local level = UnitLevel("player")
  if level < min - 2 then return "|cffff2020" end -- too high
  if level < min then return "|cffff8040" end     -- hard
  if level <= max then return "|cffffff00" end    -- on level
  if level <= max + 5 then return "|cff40c040" end -- easy
  return "|cff808080"                             -- trivial
end

function M:Update()
  local label = WorldMapFrameAreaLabel
  if not Inkmap.db.zoneLevels or not label then return end
  local name = label:GetText()
  local range = name and Inkmap_ZoneLevels[name]
  if not range then return end
  label:SetText(string.format("%s %s(%d-%d)|r", name, LevelColor(range[1], range[2]), range[1], range[2]))
end

function M:Init()
  -- the default handler rewrites the label every frame, so ours runs right after it
  Inkmap:HookScript(WorldMapButton, "OnUpdate", function() M:Update() end)
end
