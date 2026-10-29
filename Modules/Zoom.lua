-- Zooms the world map around the mouse cursor. The map detail frame is
-- moved into a ScrollFrame, which clips it, then scaled and scrolled.
-- Mouse wheel zooms, left dragging pans while zoomed in.

local Inkmap = Inkmap
local M = Inkmap:RegisterModule("zoom", {})
Inkmap.zoom = M

local MIN_ZOOM, MAX_ZOOM, ZOOM_STEP = 1, 4, 0.5
local PAN_THRESHOLD = 4
local PROBE = 100

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

-- screen pixel positions, independent of any frame scale
local function ScreenCursor()
  return GetCursorPosition()
end

local function ScreenTopLeft(frame)
  local scale = frame:GetEffectiveScale()
  return frame:GetLeft() * scale, frame:GetTop() * scale
end

function M:GetZoom()
  return WorldMapDetailFrame:GetScale()
end

-- Screen pixels the map moves per unit of scroll. Measured instead of
-- assumed, so zooming stays under the cursor whatever unit the client
-- uses for scroll offsets.
function M:MeasureScrollUnit()
  local scroll, detail = self.scroll, WorldMapDetailFrame
  scroll:SetHorizontalScroll(0)
  scroll:SetVerticalScroll(0)
  local left0, top0 = ScreenTopLeft(detail)
  scroll:SetHorizontalScroll(PROBE)
  scroll:SetVerticalScroll(PROBE)
  local left1, top1 = ScreenTopLeft(detail)

  local unitX, unitY = (left0 - left1) / PROBE, (top1 - top0) / PROBE
  if math.abs(unitX) < 0.001 or math.abs(unitY) < 0.001 then
    -- layout not updated yet: assume offsets in scroll frame units
    unitX = scroll:GetEffectiveScale()
    unitY = unitX
  end
  self.unitX, self.unitY = unitX, unitY
  self.originLeft, self.originTop = left0, top0
end

-- scroll so the detail frame's top left corner lands at screen (left, top)
function M:ScrollTo(left, top)
  local scroll, detail = self.scroll, WorldMapDetailFrame
  local detailScale = detail:GetEffectiveScale()
  local scrollScale = scroll:GetEffectiveScale()
  local maxX = detail:GetWidth() * detailScale - scroll:GetWidth() * scrollScale
  local maxY = detail:GetHeight() * detailScale - scroll:GetHeight() * scrollScale

  local shiftX = Inkmap:Clamp(self.originLeft - left, 0, math.max(maxX, 0))
  local shiftY = Inkmap:Clamp(top - self.originTop, 0, math.max(maxY, 0))
  scroll:SetHorizontalScroll(shiftX / self.unitX)
  scroll:SetVerticalScroll(shiftY / self.unitY)
end

-- keeps the map point under the cursor (or the view center) in place
function M:SetZoom(zoom)
  local scroll, detail = self.scroll, WorldMapDetailFrame
  zoom = Inkmap:Clamp(zoom, MIN_ZOOM, MAX_ZOOM)

  local x, y
  if MouseIsOver(scroll) then
    x, y = ScreenCursor()
  else
    local left, top = ScreenTopLeft(scroll)
    local scale = scroll:GetEffectiveScale()
    x, y = left + scroll:GetWidth() * scale / 2, top - scroll:GetHeight() * scale / 2
  end

  -- map point under (x, y), in detail frame units
  local left, top = ScreenTopLeft(detail)
  local oldScale = detail:GetEffectiveScale()
  local mapX, mapY = (x - left) / oldScale, (top - y) / oldScale

  detail:SetScale(zoom)
  scroll:UpdateScrollChildRect()
  self:MeasureScrollUnit()

  local newScale = detail:GetEffectiveScale()
  self:ScrollTo(x - mapX * newScale, y + mapY * newScale)
end

function M:Step(delta)
  if not WorldMapDetailFrame:GetLeft() then return end
  self:SetZoom(self:GetZoom() + delta * ZOOM_STEP)
end

function M:Reset()
  if not self.enabled or self:GetZoom() == MIN_ZOOM then return end
  if WorldMapDetailFrame:GetLeft() and WorldMapFrame:IsVisible() then
    self:SetZoom(MIN_ZOOM)
  else
    -- no layout to measure while hidden
    WorldMapDetailFrame:SetScale(MIN_ZOOM)
    self.scroll:SetHorizontalScroll(0)
    self.scroll:SetVerticalScroll(0)
  end
end

function M:Refresh()
  if self.enabled and not Inkmap.db.zoom then self:Reset() end
end

-- The 1.12 player arrow is a model drawn by the client, placed relative
-- to the detail frame in unzoomed units. Place it again for the zoom and
-- hide it while it is scrolled out of view.
function M:UpdatePlayerArrow()
  if not PositionWorldMapArrowFrame then return end
  local zoom = self:GetZoom()
  if zoom == MIN_ZOOM then return end

  local x, y = GetPlayerMapPosition("player")
  if x == 0 and y == 0 then return end

  local detail = WorldMapDetailFrame
  local offsetX, offsetY = x * detail:GetWidth() * zoom, -y * detail:GetHeight() * zoom
  PositionWorldMapArrowFrame("CENTER", "WorldMapDetailFrame", "TOPLEFT", offsetX, offsetY)

  local scale = detail:GetEffectiveScale()
  local left, top = ScreenTopLeft(detail)
  local px, py = left + x * detail:GetWidth() * scale, top - y * detail:GetHeight() * scale
  local viewLeft, viewTop = ScreenTopLeft(self.scroll)
  local viewScale = self.scroll:GetEffectiveScale()
  local inside = px >= viewLeft and px <= viewLeft + self.scroll:GetWidth() * viewScale
    and py <= viewTop and py >= viewTop - self.scroll:GetHeight() * viewScale
  if ShowWorldMapArrowFrame then ShowWorldMapArrowFrame(inside and 1 or nil) end
end

-- left drag pans the zoomed map; a drag must not count as a click
function M:HookPanning()
  Inkmap:HookScript(WorldMapButton, "OnMouseDown", function()
    M.panned = false
    if arg1 ~= "LeftButton" or M:GetZoom() <= MIN_ZOOM then return end
    M.panning = true
    M.startX, M.startY = ScreenCursor()
    M.startLeft, M.startTop = ScreenTopLeft(WorldMapDetailFrame)
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
    local x, y = ScreenCursor()
    local dx, dy = x - M.startX, y - M.startY
    if not M.panned and math.abs(dx) + math.abs(dy) < PAN_THRESHOLD then return end
    M.panned = true
    M:ScrollTo(M.startLeft + dx, M.startTop + dy)
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

  self:HookPanning()
  Inkmap:HookScript(WorldMapButton, "OnUpdate", function() M:UpdatePlayerArrow() end)

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
end
