-- Player and cursor coordinates: in the strip below the map in window
-- mode, on top of the map itself in fullscreen mode.

local Inkmap = Inkmap
local M = Inkmap:RegisterModule("coords", {})

local UPDATE_INTERVAL = 0.05
local LABEL = "|cffffd100%s|r %.1f, %.1f"

-- cursor position on the map in percent, or nil when not over the map
local function GetCursorCoords()
  local view = Inkmap.zoom.scroll or WorldMapButton
  if not MouseIsOver(view) then return end
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
    self.player:SetText("")
  else
    self.player:SetText(string.format(LABEL, "Player:", x * 100, y * 100))
  end

  local cx, cy = GetCursorCoords()
  if cx then
    self.cursor:SetText(string.format(LABEL, "Cursor:", cx, cy))
  else
    self.cursor:SetText("")
  end
end

function M:Refresh()
  if not self.frame then return end
  if Inkmap.db.coords then self.frame:Show() else self.frame:Hide() end
end

function M:Init()
  local window = Inkmap.window
  local frame = CreateFrame("Frame", "InkmapCoordsFrame", WorldMapFrame)
  self.frame = frame
  self.cursor = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  self.player = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")

  if window.enabled then
    -- footer strip, clear of the corner ornaments
    local inset = window.cornerSize - 2
    frame:SetPoint("BOTTOMLEFT", WorldMapFrame, "BOTTOMLEFT", 0, 0)
    frame:SetPoint("BOTTOMRIGHT", WorldMapFrame, "BOTTOMRIGHT", 0, 0)
    frame:SetHeight(window.footerHeight)
    self.cursor:SetPoint("LEFT", frame, "LEFT", inset, 0)
    self.player:SetPoint("RIGHT", frame, "RIGHT", -inset, 0)
  else
    frame:SetAllPoints(WorldMapButton)
    self.cursor:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 8)
    self.player:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 8)
  end
  frame:SetFrameLevel(WorldMapFrame:GetFrameLevel() + 50)

  frame.elapsed = 0
  frame:SetScript("OnUpdate", function()
    this.elapsed = this.elapsed + arg1
    if this.elapsed < UPDATE_INTERVAL then return end
    this.elapsed = 0
    M:Update()
  end)

  self:Refresh()
end
