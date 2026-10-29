-- Minimap button: left click toggles the world map, right click opens
-- the options, drag to move it around the minimap.

local Inkmap = Inkmap
local M = Inkmap:RegisterModule("minimap", {})

local RADIUS = 80

function M:UpdatePosition()
  local angle = math.rad(Inkmap.db.minimapAngle)
  self.button:SetPoint("CENTER", Minimap, "CENTER", RADIUS * math.cos(angle), RADIUS * math.sin(angle))
end

function M:Refresh()
  if not self.button then return end
  if Inkmap.db.minimap then self.button:Show() else self.button:Hide() end
end

function M:Init()
  local button = CreateFrame("Button", "InkmapMinimapButton", Minimap)
  button:SetWidth(31)
  button:SetHeight(31)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel(8)
  button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:RegisterForDrag("LeftButton")
  self.button = button

  local icon = button:CreateTexture(nil, "BACKGROUND")
  icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
  icon:SetWidth(20)
  icon:SetHeight(20)
  icon:SetPoint("TOPLEFT", button, "TOPLEFT", 7, -5)

  local border = button:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetWidth(53)
  border:SetHeight(53)
  border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)

  button:SetScript("OnClick", function()
    if arg1 == "RightButton" then
      Inkmap.options:Toggle()
    else
      ToggleWorldMap()
    end
  end)

  button:SetScript("OnDragStart", function()
    this:SetScript("OnUpdate", function()
      local x, y = GetCursorPosition()
      local scale = Minimap:GetEffectiveScale()
      local cx, cy = Minimap:GetCenter()
      Inkmap.db.minimapAngle = math.deg(math.atan2(y / scale - cy, x / scale - cx))
      M:UpdatePosition()
    end)
  end)
  button:SetScript("OnDragStop", function()
    this:SetScript("OnUpdate", nil)
  end)

  button:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:AddLine("Inkmap")
    GameTooltip:AddLine("Left click: toggle world map", 1, 1, 1)
    GameTooltip:AddLine("Right click: options", 1, 1, 1)
    GameTooltip:AddLine("Drag: move this button", 1, 1, 1)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function() GameTooltip:Hide() end)

  self:UpdatePosition()
  self:Refresh()
end
