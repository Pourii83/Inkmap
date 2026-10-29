-- Player and cursor coordinates at the bottom of the world map.

local Inkmap = Inkmap
local M = Inkmap:RegisterModule("coords", {})

local UPDATE_INTERVAL = 0.05

-- cursor position on the map in percent, or nil when not over the map
local function GetCursorCoords()
  if not MouseIsOver(WorldMapButton) then return end
  local left, top = WorldMapButton:GetLeft(), WorldMapButton:GetTop()
  if not left then return end
  local scale = WorldMapButton:GetEffectiveScale()
  local x, y = GetCursorPosition()
  x = (x / scale - left) / WorldMapButton:GetWidth()
  y = (top - y / scale) / WorldMapButton:GetHeight()
  if x < 0 or x > 1 or y < 0 or y > 1 then return end
  return x * 100, y * 100
end

function M:Update()
  local x, y = GetPlayerMapPosition("player")
  if x == 0 and y == 0 then
    self.player:SetText("Player: --")
  else
    self.player:SetText(string.format("Player: %.1f, %.1f", x * 100, y * 100))
  end

  local cx, cy = GetCursorCoords()
  if cx then
    self.cursor:SetText(string.format("Cursor: %.1f, %.1f", cx, cy))
  else
    self.cursor:SetText("")
  end
end

function M:Refresh()
  if not self.frame then return end
  if Inkmap.db.coords then self.frame:Show() else self.frame:Hide() end
end

function M:Init()
  local frame = CreateFrame("Frame", "InkmapCoordsFrame", WorldMapFrame)
  frame:SetAllPoints(WorldMapButton)
  frame:SetFrameLevel(WorldMapButton:GetFrameLevel() + 5)
  self.frame = frame

  self.player = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.player:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 8)
  self.cursor = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.cursor:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 8)

  frame.elapsed = 0
  frame:SetScript("OnUpdate", function()
    this.elapsed = this.elapsed + arg1
    if this.elapsed < UPDATE_INTERVAL then return end
    this.elapsed = 0
    M:Update()
  end)

  self:Refresh()
end
