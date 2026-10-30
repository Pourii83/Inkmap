-- Turns the fullscreen world map into a movable, resizable window that
-- lets you keep playing while it is open, and fades it while moving.

local Inkmap = Inkmap
local M = Inkmap:RegisterModule("window", {})
Inkmap.window = M

local UPDATE_INTERVAL = 0.1

-- window layout around the 1002x668 map
local MAP_WIDTH, MAP_HEIGHT = 1002, 668
-- PAD is the grabbable band between the silver border and the map
local PAD, HEADER, FOOTER = 12, 30, 28
local EDGE, EDGE_OFFSET = 24, 2
M.footerHeight, M.cornerSize = FOOTER, EDGE + 4

local WHITE = "Interface\\Buttons\\WHITE8X8"
local DIALOG_BORDER = "Interface\\DialogFrame\\UI-DialogBox-Border"
local BORDER_COLOR, BORDER_HOVER = 0.8, 1

-- dropdowns made from UIDropDownMenuTemplate have these child regions
local function IsDropDown(frame)
  local name = frame:GetName()
  return name and getglobal(name .. "Button") and getglobal(name .. "Text") and true
end

local function Suppress(frame)
  frame:Hide()
  frame.Show = function() end
end

-- removes the fullscreen parchment art and the "World Map" title
local function StripRegions(frame)
  for _, region in ipairs({ frame:GetRegions() }) do
    if region.SetTexture then
      region:SetTexture(nil)
    elseif region.SetText then
      region:Hide()
    end
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
  frame:SetWidth(MAP_WIDTH + PAD * 2)
  frame:SetHeight(self:GetHeader() + MAP_HEIGHT + FOOTER)
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

-- Resizing keeps the map's aspect ratio by scaling the window, with its
-- top left corner pinned while the grip follows the cursor.
function M:StartResize()
  local frame = WorldMapFrame
  local scale = frame:GetEffectiveScale()
  self.resizeLeft, self.resizeTop = frame:GetLeft() * scale, frame:GetTop() * scale
  self.resizing = true
end

function M:UpdateResize()
  if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then
    self:StopResize()
    return
  end
  local db, frame = Inkmap.db, WorldMapFrame
  local x, y = GetCursorPosition()
  local parentScale = frame:GetEffectiveScale() / frame:GetScale()
  local scaleX = (x - self.resizeLeft) / (frame:GetWidth() * parentScale)
  local scaleY = (self.resizeTop - y) / (frame:GetHeight() * parentScale)
  db.scale = Inkmap:Clamp(math.min(scaleX, scaleY), 0.4, 1.5)

  frame:SetScale(db.scale)
  local scale = frame:GetEffectiveScale()
  frame:ClearAllPoints()
  frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.resizeLeft / scale, self.resizeTop / scale)
end

function M:StopResize()
  if not self.resizing then return end
  self.resizing = false
  self:SavePosition()
  self:Apply()
  Inkmap:Refresh()
end

-- the bottom right corner ornament doubles as the resize handle: a copy
-- of that corner piece drawn over the border, which lights up on hover
function M:CreateResizeHandle(border)
  local corner = CreateFrame("Frame", nil, border)
  corner:SetWidth(EDGE)
  corner:SetHeight(EDGE)
  corner:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 0, 0)
  corner:SetFrameLevel(border:GetFrameLevel() + 1)
  local texture = corner:CreateTexture(nil, "OVERLAY")
  texture:SetTexture(DIALOG_BORDER)
  -- an edge file holds 8 pieces side by side; the last is the bottom right corner
  texture:SetTexCoord(7 / 8, 1, 0, 1)
  texture:SetAllPoints(corner)
  texture:SetVertexColor(BORDER_COLOR, BORDER_COLOR, BORDER_COLOR, 1)
  self.resizeHandle = corner

  corner:EnableMouse(true)
  corner:SetScript("OnMouseDown", function()
    if arg1 == "LeftButton" and not Inkmap.db.locked then M:StartResize() end
  end)
  corner:SetScript("OnMouseUp", function() M:StopResize() end)
  corner:SetScript("OnUpdate", function()
    if M.resizing then M:UpdateResize() end
  end)
  corner:SetScript("OnEnter", function()
    texture:SetVertexColor(BORDER_HOVER, BORDER_HOVER, BORDER_HOVER, 1)
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText("Drag to resize the map")
    GameTooltip:Show()
  end)
  corner:SetScript("OnLeave", function()
    texture:SetVertexColor(BORDER_COLOR, BORDER_COLOR, BORDER_COLOR, 1)
    GameTooltip:Hide()
  end)
end

-- dark frame with a silver border, like the modern map
function M:Style()
  local frame = WorldMapFrame
  StripRegions(frame)
  if BlackoutWorld then BlackoutWorld:Hide() end
  if WorldMapMagnifyingGlassButton then WorldMapMagnifyingGlassButton:Hide() end

  frame:SetBackdrop({
    bgFile = WHITE, edgeFile = WHITE, tile = false, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
  })
  frame:SetBackdropColor(0.06, 0.06, 0.06, 0.95)
  frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

  -- dark line around the map itself
  local line = CreateFrame("Frame", nil, frame)
  line:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
  line:SetBackdropBorderColor(0, 0, 0, 1)
  self.mapLine = line

  -- silver edge all around, drawn over the map so the corners overlap it;
  -- not mouse enabled, so the window under it still takes the drag
  local border = CreateFrame("Frame", nil, frame)
  border:SetPoint("TOPLEFT", frame, "TOPLEFT", -EDGE_OFFSET, EDGE_OFFSET)
  border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", EDGE_OFFSET, -EDGE_OFFSET)
  border:SetFrameLevel(frame:GetFrameLevel() + 60)
  border:SetBackdrop({ edgeFile = DIALOG_BORDER, edgeSize = EDGE })
  border:SetBackdropBorderColor(BORDER_COLOR, BORDER_COLOR, BORDER_COLOR, 1)

  self:CreateResizeHandle(border)
end

-- Hides the map's buttons and dropdowns, including ones other addons put
-- on the map (pfQuest's quest filter for example). Right click still
-- zooms the map out, and ESC or the map key close it.
function M:HideControls()
  if not Inkmap.db.hideControls then return end
  local fixed = { WorldMapContinentDropDown, WorldMapZoneDropDown, WorldMapZoneMinimapDropDown,
    WorldMapZoomOutButton, WorldMapFrameCloseButton }
  for _, frame in pairs(fixed) do Suppress(frame) end

  for _, parent in ipairs({ WorldMapFrame, WorldMapButton }) do
    for _, child in ipairs({ parent:GetChildren() }) do
      if IsDropDown(child) then Suppress(child) end
    end
  end
end

function M:GetHeader()
  if Inkmap.db.hideControls then return PAD end
  return HEADER
end

-- places the map between the header (dropdowns) and the footer (coordinates)
function M:Layout()
  local frame = WorldMapFrame
  local map = Inkmap.zoom.scroll or WorldMapDetailFrame
  map:ClearAllPoints()
  map:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -self:GetHeader())

  -- 1.12 anchors the map and its extras to this guide; keep the guide
  -- where it was relative to the map (map top left = guide top - 502, -69)
  WorldMapPositioningGuide:ClearAllPoints()
  WorldMapPositioningGuide:SetPoint("TOP", map, "TOPLEFT", 502, 69)

  self.mapLine:ClearAllPoints()
  self.mapLine:SetPoint("TOPLEFT", map, "TOPLEFT", -1, 1)
  self.mapLine:SetPoint("BOTTOMRIGHT", map, "BOTTOMRIGHT", 1, -1)

  -- the zone dropdown and zoom out button are chained to this one
  WorldMapContinentDropDown:ClearAllPoints()
  WorldMapContinentDropDown:SetPoint("LEFT", frame, "TOPLEFT", 14, -HEADER / 2 - 2)
  WorldMapFrameCloseButton:ClearAllPoints()
  WorldMapFrameCloseButton:SetPoint("RIGHT", frame, "TOPRIGHT", -24, -HEADER / 2)

  -- the zone name label lives inside the map button; keep it on top of the
  -- map without zooming or scrolling along
  local area = WorldMapFrameAreaFrame
  if area then
    area:SetParent(frame)
    area:ClearAllPoints()
    area:SetPoint("TOP", map, "TOP", 0, -10)
    area:SetFrameLevel(map:GetFrameLevel() + 30)
  end
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

local FADE_STEP = 0.15

-- the map turns a bit transparent while the mouse is away from it, and
-- more so while moving; 'smooth' eases toward the target instead of jumping
function M:UpdateAlpha(smooth)
  local db, frame = Inkmap.db, WorldMapFrame
  local target = db.alpha
  if not MouseIsOver(frame) then
    if db.fadeAway then target = math.min(target, db.awayAlpha) end
    if db.fade and self.moving then target = math.min(target, db.fadeAlpha) end
  end

  local alpha = frame:GetAlpha()
  if smooth then
    if alpha < target then
      alpha = math.min(alpha + FADE_STEP, target)
    else
      alpha = math.max(alpha - FADE_STEP, target)
    end
  else
    alpha = target
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

  self:Style()
  self:Layout()
  self:HideControls()

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
      Inkmap.zoom:Step(arg1)
    end
  end)

  -- the default OnShow resets scale and grabs the keyboard; undo that
  Inkmap:HookScript(frame, "OnShow", function()
    WorldMapFrame:EnableKeyboard(false)
    -- catches dropdowns that addons created after login
    M:HideControls()
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
    M:UpdateAlpha(true)
  end)
  driver:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  driver:SetScript("OnEvent", function()
    if Inkmap.db.autoZone and WorldMapFrame:IsShown() then
      SetMapToCurrentZone()
    end
  end)

  self:Apply()
end
