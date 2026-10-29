-- Zooms the world map. The map detail frame is moved into a ScrollFrame,
-- which clips it, then scaled and scrolled. Mouse wheel zooms around the
-- cursor, the +/- buttons zoom around the center, and left dragging pans
-- while zoomed in. Based on the approach of the Magnify addon.

local Inkmap = Inkmap
local M = Inkmap:RegisterModule("zoom", {})
Inkmap.zoom = M

local MIN_ZOOM, MAX_ZOOM, ZOOM_STEP = 1, 4, 0.5
local PAN_THRESHOLD = 4

-- moves frames anchored to the detail frame over to the scroll frame,
-- so labels and buttons stay in place while the map itself zooms
local function MoveAnchors(scroll)
  for _, child in ipairs({ WorldMapFrame:GetChildren() }) do
    if child ~= scroll then
      local numPoints = child.GetNumPoints and child:GetNumPoints() or 1
      local points, moved = {}, false
      for i = 1, numPoints do
        local point, rel, relPoint, x, y = child:GetPoint(i)
        if rel == WorldMapDetailFrame then rel, moved = scroll, true end
        if point then points[i] = { point, rel, relPoint, x, y } end
      end
      if moved then
        child:ClearAllPoints()
        for _, p in ipairs(points) do
          child:SetPoint(p[1], p[2], p[3], p[4], p[5])
        end
      end
    end
  end
end

function M:GetZoom()
  return WorldMapDetailFrame:GetScale()
end

-- cursor position inside the scroll frame, top left is 0,0
function M:GetCursor()
  local scroll = self.scroll
  local scale = scroll:GetEffectiveScale()
  local x, y = GetCursorPosition()
  return x / scale - scroll:GetLeft(), scroll:GetTop() - y / scale
end

function M:SetScroll(h, v)
  local scroll, zoom = self.scroll, self:GetZoom()
  local maxH = WorldMapDetailFrame:GetWidth() * zoom - scroll:GetWidth()
  local maxV = WorldMapDetailFrame:GetHeight() * zoom - scroll:GetHeight()
  scroll:SetHorizontalScroll(Inkmap:Clamp(h, 0, math.max(maxH, 0)))
  scroll:SetVerticalScroll(Inkmap:Clamp(v, 0, math.max(maxV, 0)))
end

-- zooms so the map point under (fx, fy) of the scroll frame stays put
function M:SetZoom(zoom, fx, fy)
  local scroll = self.scroll
  local old = self:GetZoom()
  zoom = Inkmap:Clamp(zoom, MIN_ZOOM, MAX_ZOOM)
  if not fx then fx, fy = scroll:GetWidth() / 2, scroll:GetHeight() / 2 end

  local h = scroll:GetHorizontalScroll()
  local v = scroll:GetVerticalScroll()
  WorldMapDetailFrame:SetScale(zoom)
  scroll:UpdateScrollChildRect()
  self:SetScroll(zoom / old * (fx + h) - fx, zoom / old * (fy + v) - fy)
  self:UpdateButtons()
end

function M:Step(delta, atCursor)
  if atCursor and MouseIsOver(self.scroll) then
    local fx, fy = self:GetCursor()
    self:SetZoom(self:GetZoom() + delta * ZOOM_STEP, fx, fy)
  else
    self:SetZoom(self:GetZoom() + delta * ZOOM_STEP)
  end
end

function M:Reset()
  if self.enabled then self:SetZoom(MIN_ZOOM) end
end

function M:UpdateButtons()
  local zoom = self:GetZoom()
  if zoom < MAX_ZOOM then self.zoomIn:Enable() else self.zoomIn:Disable() end
  if zoom > MIN_ZOOM then self.zoomOut:Enable() else self.zoomOut:Disable() end
end

function M:Refresh()
  if not self.enabled then return end
  if Inkmap.db.zoom then
    self.zoomIn:Show()
    self.zoomOut:Show()
  else
    self.zoomIn:Hide()
    self.zoomOut:Hide()
    self:Reset()
  end
end

local function CreateZoomButton(name, texture, anchor, offsetY, delta)
  local button = CreateFrame("Button", name, M.scroll)
  button:SetWidth(32)
  button:SetHeight(32)
  button:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", -6, offsetY)
  button:SetFrameLevel(M.scroll:GetFrameLevel() + 20)
  button:SetNormalTexture(texture .. "-Up")
  button:SetPushedTexture(texture .. "-Down")
  button:SetDisabledTexture(texture .. "-Disabled")
  button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  button:SetScript("OnClick", function() M:Step(delta) end)
  return button
end

-- left drag pans the zoomed map; a drag must not count as a click
function M:HookPanning()
  Inkmap:HookScript(WorldMapButton, "OnMouseDown", function()
    if arg1 ~= "LeftButton" or M:GetZoom() <= MIN_ZOOM then return end
    M.panning = true
    M.panned = false
    M.startX, M.startY = M:GetCursor()
    M.startH, M.startV = M.scroll:GetHorizontalScroll(), M.scroll:GetVerticalScroll()
  end)
  Inkmap:HookScript(WorldMapButton, "OnMouseUp", function()
    if arg1 == "LeftButton" then M.panning = false end
  end)

  local onClick = WorldMapButton:GetScript("OnClick")
  WorldMapButton:SetScript("OnClick", function(a1, a2, a3)
    if M.panned then
      M.panned = false
      return
    end
    if onClick then onClick(a1, a2, a3) end
  end)

  self.scroll:SetScript("OnUpdate", function()
    if not M.panning then return end
    if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then
      M.panning = false
      return
    end
    local x, y = M:GetCursor()
    local dx, dy = x - M.startX, y - M.startY
    if not M.panned and math.abs(dx) + math.abs(dy) < PAN_THRESHOLD then return end
    M.panned = true
    M:SetScroll(M.startH - dx, M.startV - dy)
  end)
end

function M:Init()
  -- the scroll frame needs the fixed size map of the window mode
  if not Inkmap.window.enabled then return end
  self.enabled = true

  local detail = WorldMapDetailFrame
  if WorldMapButton:GetParent() ~= detail then WorldMapButton:SetParent(detail) end

  local scroll = CreateFrame("ScrollFrame", "InkmapZoomFrame", WorldMapFrame)
  scroll:SetWidth(detail:GetWidth())
  scroll:SetHeight(detail:GetHeight())
  local point, rel, relPoint, x, y = detail:GetPoint()
  scroll:SetPoint(point or "CENTER", rel or WorldMapFrame, relPoint or "CENTER", x or 0, y or 0)
  scroll:SetFrameLevel(detail:GetFrameLevel())
  scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel", function()
    local handler = WorldMapFrame:GetScript("OnMouseWheel")
    if handler then handler() end
  end)
  self.scroll = scroll

  MoveAnchors(scroll)
  detail:SetParent(scroll)
  detail:ClearAllPoints()
  detail:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
  scroll:SetScrollChild(detail)

  self.zoomIn = CreateZoomButton("InkmapZoomInButton", "Interface\\Minimap\\UI-Minimap-ZoomInButton", scroll, -6, 1)
  self.zoomOut = CreateZoomButton("InkmapZoomOutButton", "Interface\\Minimap\\UI-Minimap-ZoomOutButton", scroll, -36, -1)
  self:HookPanning()

  -- start unzoomed whenever the map shows a different zone
  local original = WorldMapFrame_Update
  WorldMapFrame_Update = function(a1, a2, a3)
    original(a1, a2, a3)
    local mapFile = GetMapInfo()
    if mapFile ~= M.mapFile then
      M.mapFile = mapFile
      M:Reset()
    end
  end

  self:UpdateButtons()
  self:Refresh()
end
