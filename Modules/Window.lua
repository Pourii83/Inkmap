-- Turns the fullscreen world map into a movable, scalable window that
-- lets you keep playing while it is open, and fades it while moving.

local Inkmap = Inkmap
local M = Inkmap:RegisterModule("window", {})
Inkmap.window = M

local UPDATE_INTERVAL = 0.1

local function StripTextures(frame)
  for _, region in ipairs({ frame:GetRegions() }) do
    if region.SetTexture then region:SetTexture(nil) end
  end
end

-- Turtle WoW ships its own minimized map mode; force the full size map
-- and keep it from switching back.
local function DisableTurtleMapModes()
  if not WorldMapFrame_Maximize then return end

  WorldMapFrame_Maximize()
  WorldMapFrame_Minimize = function() end
  WorldMapFrame_Maximize = function() end

  local hide = { WorldMapFrameMaximizeButton, WorldMapFrameMinimizeButton, WorldMapFrameTitle }
  for _, region in pairs(hide) do
    region.Show = function() end
    region:Hide()
  end
end

-- position is stored as the frame center in screen pixels, so it does
-- not depend on the frame's scale or parent
function M:SavePosition()
  local frame = WorldMapFrame
  local x, y = frame:GetCenter()
  if not x then return end
  local scale = frame:GetEffectiveScale()
  Inkmap.db.x, Inkmap.db.y = x * scale, y * scale
end

function M:Apply()
  local db, frame = Inkmap.db, WorldMapFrame

  frame:SetScale(db.scale)
  frame:SetWidth(WorldMapButton:GetWidth() + 15)
  frame:SetHeight(WorldMapButton:GetHeight() + 55)
  frame:ClearAllPoints()
  if db.x and db.y then
    local scale = frame:GetEffectiveScale()
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", db.x / scale, db.y / scale)
  else
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  end

  self:UpdateAlpha()
end

function M:SetScale(scale)
  Inkmap.db.scale = Inkmap:Clamp(math.floor(scale * 100 + 0.5) / 100, 0.4, 1.5)
  if not self.enabled then return end
  -- keep the map centered on the same spot while it grows or shrinks
  self:SavePosition()
  self:Apply()
end

function M:Reset()
  local db = Inkmap.db
  db.x, db.y = nil, nil
  db.scale = Inkmap.defaults.scale
  db.alpha = Inkmap.defaults.alpha
  if self.enabled then self:Apply() end
  Inkmap.zoom:Reset()
  Inkmap:Refresh()
end

function M:UpdateAlpha()
  local db, frame = Inkmap.db, WorldMapFrame
  local alpha = db.alpha
  if db.fade and self.moving and not MouseIsOver(frame) then
    alpha = math.min(alpha, db.fadeAlpha)
  end
  if frame:GetAlpha() ~= alpha then frame:SetAlpha(alpha) end
end

-- the 1.12 API has no movement events, so watch the player's map position
function M:UpdateMoving()
  local x, y = GetPlayerMapPosition("player")
  self.moving = (self.lastX ~= nil) and (x ~= self.lastX or y ~= self.lastY) and not (x == 0 and y == 0)
  self.lastX, self.lastY = x, y
end

function M:Refresh()
  if self.enabled then self:Apply() end
end

function M:Init()
  if not Inkmap.db.window or Inkmap.conflict then return end
  self.enabled = true

  local frame = WorldMapFrame
  DisableTurtleMapModes()

  -- not a managed UI panel any more: ShowUIPanel/HideUIPanel now simply
  -- show and hide it, and it no longer hides the rest of the interface
  UIPanelWindows["WorldMapFrame"] = nil
  table.insert(UISpecialFrames, "WorldMapFrame")
  ToggleWorldMap = function()
    if WorldMapFrame:IsShown() then WorldMapFrame:Hide() else WorldMapFrame:Show() end
  end

  if BlackoutWorld then BlackoutWorld:Hide() end
  StripTextures(frame)
  frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  frame:SetBackdropColor(0, 0, 0, 0.85)
  frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

  WorldMapFrameCloseButton:ClearAllPoints()
  WorldMapFrameCloseButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 2, 2)

  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:EnableMouse(true)
  frame:EnableMouseWheel(true)
  frame:RegisterForDrag("LeftButton")

  frame:SetScript("OnDragStart", function()
    if not Inkmap.db.locked then this:StartMoving() end
  end)
  frame:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    if this.SetUserPlaced then this:SetUserPlaced(false) end
    M:SavePosition()
    M:Apply()
  end)
  frame:SetScript("OnMouseWheel", function()
    if IsControlKeyDown() then
      M:SetScale(Inkmap.db.scale + arg1 * 0.05)
      Inkmap:Refresh()
    elseif IsShiftKeyDown() then
      Inkmap.db.alpha = Inkmap:Clamp(Inkmap.db.alpha + arg1 * 0.05, 0.2, 1)
      M:UpdateAlpha()
      Inkmap:Refresh()
    elseif Inkmap.zoom.enabled and Inkmap.db.zoom then
      Inkmap.zoom:Step(arg1, true)
    end
  end)

  -- the default OnShow resets scale and grabs the keyboard; undo that
  Inkmap:HookScript(frame, "OnShow", function()
    WorldMapFrame:EnableKeyboard(false)
    M.lastX, M.moving = nil, false
    M:Apply()
  end)

  -- a child frame only receives OnUpdate while the map is shown
  local driver = CreateFrame("Frame", nil, frame)
  driver.elapsed = 0
  driver:SetScript("OnUpdate", function()
    this.elapsed = this.elapsed + arg1
    if this.elapsed < UPDATE_INTERVAL then return end
    this.elapsed = 0
    M:UpdateMoving()
    M:UpdateAlpha()
  end)
  driver:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  driver:SetScript("OnEvent", function()
    if Inkmap.db.autoZone and WorldMapFrame:IsShown() then
      SetMapToCurrentZone()
    end
  end)

  self:Apply()
end
