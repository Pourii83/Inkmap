-- Shows unexplored areas of the world map. The 1.12 API only reports
-- explored overlays, so the full overlay list comes from the Data folder.
-- Rendering is based on pfUI's mapreveal module (MIT, Shagu).

local Inkmap = Inkmap
local M = Inkmap:RegisterModule("reveal", {})

local TILE = 256

-- zones that only exist on Turtle WoW based clients
local TURTLE_ZONES = {
  ["Gilneas"] = true, ["Hyjal"] = true, ["Tel'Abim"] = true,
  ["Gillijim's Isle"] = true, ["Lapidis Isle"] = true, ["Thalassian Highlands"] = true,
}

-- overlays whose offsets in the data are a few pixels off
local ERRATA = {
  ["Interface\\WorldMap\\Tirisfal\\BRIGHTWATERLAKE"] = { offsetX = { 587, 584 } },
  ["Interface\\WorldMap\\Silverpine\\BERENSPERIL"] = { offsetY = { 417, 415 } },
}

local function IsTurtleClient()
  if TargetHPText and TargetHPPercText then return true end
  for continent = 1, 2 do
    for _, zone in ipairs({ GetMapZones(continent) }) do
      if TURTLE_ZONES[zone] then return true end
    end
  end
  return false
end

function M:GetData()
  local choice = Inkmap.db.overlayData
  if choice == "auto" then
    if self.turtle == nil then self.turtle = IsTurtleClient() end
    choice = self.turtle and "turtle" or "vanilla"
  end
  if choice == "turtle" then return Inkmap_OverlayData_Turtle end
  return Inkmap_OverlayData_Vanilla
end

-- "NAME:width:height:offsetX:offsetY"
local function ParseOverlay(entry)
  local _, _, name, width, height, x, y = string.find(entry, "^([^:]+):(%d+):(%d+):(%d+):(%d+)")
  if not name then return end
  return name, tonumber(width), tonumber(height), tonumber(x), tonumber(y)
end

local function GetOverlayTexture(index)
  local texture = getglobal("WorldMapOverlay" .. index)
  if not texture then
    texture = WorldMapDetailFrame:CreateTexture("WorldMapOverlay" .. index, "ARTWORK")
  end
  if index > NUM_WORLDMAP_OVERLAYS then NUM_WORLDMAP_OVERLAYS = index end
  return texture
end

-- size of the last tile in a row or column, and the power of two file size holding it
local function TileSize(total, isLast)
  if not isLast then return TILE, TILE end
  local pixels = math.mod(total, TILE)
  if pixels == 0 then pixels = TILE end
  local file = 16
  while file < pixels do file = file * 2 end
  return pixels, file
end

-- draws one overlay starting at texture slot 'count + 1', returns the new count
local function DrawOverlay(count, path, width, height, offsetX, offsetY, r, g, b, a)
  local tilesX = math.ceil(width / TILE)
  local tilesY = math.ceil(height / TILE)
  for row = 1, tilesY do
    local pixelHeight, fileHeight = TileSize(height, row == tilesY)
    for col = 1, tilesX do
      local pixelWidth, fileWidth = TileSize(width, col == tilesX)
      count = count + 1
      local texture = GetOverlayTexture(count)
      texture:SetWidth(pixelWidth)
      texture:SetHeight(pixelHeight)
      texture:SetTexCoord(0, pixelWidth / fileWidth, 0, pixelHeight / fileHeight)
      texture:ClearAllPoints()
      texture:SetPoint("TOPLEFT", "WorldMapDetailFrame", "TOPLEFT", offsetX + TILE * (col - 1), -(offsetY + TILE * (row - 1)))
      texture:SetTexture(path .. ((row - 1) * tilesX + col))
      texture:SetVertexColor(r, g, b, a)
      texture:Show()
    end
  end
  return count
end

-- runs after the default WorldMapFrame_Update has drawn the explored overlays
function M:Update()
  -- texture slots the default code used, and which overlays it knows
  local used, known = 0, {}
  for i = 1, GetNumMapOverlays() do
    local path, width, height = GetMapOverlayInfo(i)
    if path then
      known[path] = true
      used = used + math.ceil(width / TILE) * math.ceil(height / TILE)
    end
  end

  -- slots may still carry the tint from an earlier zone
  for i = 1, math.min(used, NUM_WORLDMAP_OVERLAYS) do
    getglobal("WorldMapOverlay" .. i):SetVertexColor(1, 1, 1, 1)
  end

  local db = Inkmap.db
  if not db.reveal then return end

  local mapFile = GetMapInfo()
  local zone = mapFile and self:GetData()[mapFile]
  if not zone then return end

  local r, g, b, a = 1, 1, 1, 1
  if db.revealTint then r, g, b, a = db.tint.r, db.tint.g, db.tint.b, db.tint.a end

  local prefix = "Interface\\WorldMap\\" .. mapFile .. "\\"
  local count = used
  for _, entry in ipairs(zone) do
    local name, width, height, offsetX, offsetY = ParseOverlay(entry)
    local path = name and prefix .. name
    if path and not known[path] then
      local fix = ERRATA[path]
      if fix and fix.offsetX and fix.offsetX[1] == offsetX then offsetX = fix.offsetX[2] end
      if fix and fix.offsetY and fix.offsetY[1] == offsetY then offsetY = fix.offsetY[2] end
      count = DrawOverlay(count, path, width, height, offsetX, offsetY, r, g, b, a)
    end
  end
end

function M:Refresh()
  if self.enabled and WorldMapFrame:IsShown() then WorldMapFrame_Update() end
end

function M:Init()
  if Inkmap.conflict then return end
  self.enabled = true

  local original = WorldMapFrame_Update
  WorldMapFrame_Update = function(a1, a2, a3)
    for i = 1, NUM_WORLDMAP_OVERLAYS do
      getglobal("WorldMapOverlay" .. i):Hide()
    end
    original(a1, a2, a3)
    M:Update()
  end
end
