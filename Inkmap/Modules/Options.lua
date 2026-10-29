-- Options window, opened with /inkmap or a right click on the minimap button.

local Inkmap = Inkmap
local M = Inkmap:RegisterModule("options", {})
Inkmap.options = M

local CHECKBOXES = {
  { key = "window", label = "Windowed, movable map", tip = "Needs a /reload to switch back to the fullscreen map." },
  { key = "locked", label = "Lock map position" },
  { key = "fade", label = "Fade map while moving", tip = "The map turns solid again while the mouse is over it." },
  { key = "autoZone", label = "Follow zone changes", tip = "Switch the open map to the zone you just entered." },
  { key = "reveal", label = "Show unexplored areas" },
  { key = "revealTint", label = "Tint unexplored areas" },
  { key = "coords", label = "Show coordinates" },
  { key = "zoneLevels", label = "Show zone level ranges" },
  { key = "minimap", label = "Show minimap button" },
}

local SLIDERS = {
  { key = "scale", label = "Map scale", min = 0.4, max = 1.5, step = 0.05 },
  { key = "alpha", label = "Map opacity", min = 0.2, max = 1, step = 0.05 },
  { key = "fadeAlpha", label = "Opacity while moving", min = 0.1, max = 1, step = 0.05 },
}

local function CreateCheckbox(parent, index, info)
  local name = "InkmapOptionsCheck" .. index
  local check = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
  check:SetWidth(26)
  check:SetHeight(26)
  check:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -36 - (index - 1) * 26)
  getglobal(name .. "Text"):SetText(info.label)
  check.info = info

  check:SetScript("OnClick", function()
    local key = this.info.key
    Inkmap.db[key] = this:GetChecked() and true or false
    if key == "window" then
      Inkmap:Print("type /reload to apply the map window setting.")
    end
    Inkmap:Refresh()
  end)
  if info.tip then
    check:SetScript("OnEnter", function()
      GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
      GameTooltip:SetText(this.info.tip, 1, 1, 1, 1, 1)
      GameTooltip:Show()
    end)
    check:SetScript("OnLeave", function() GameTooltip:Hide() end)
  end
  return check
end

local function SliderText(info, value)
  return string.format("%s: %d%%", info.label, math.floor(value * 100 + 0.5))
end

local function CreateSlider(parent, index, info, top)
  local name = "InkmapOptionsSlider" .. index
  local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
  slider:SetWidth(220)
  slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 24, top - (index - 1) * 44)
  slider:SetMinMaxValues(info.min, info.max)
  slider:SetValueStep(info.step)
  getglobal(name .. "Low"):SetText(math.floor(info.min * 100) .. "%")
  getglobal(name .. "High"):SetText(math.floor(info.max * 100) .. "%")
  slider.info = info

  slider:SetScript("OnValueChanged", function()
    if M.updating then return end
    local value = this:GetValue()
    getglobal(this:GetName() .. "Text"):SetText(SliderText(this.info, value))
    if this.info.key == "scale" then
      Inkmap.window:SetScale(value)
    else
      Inkmap.db[this.info.key] = value
      Inkmap:Refresh()
    end
  end)
  return slider
end

function M:Create()
  local frame = CreateFrame("Frame", "InkmapOptionsFrame", UIParent)
  frame:SetWidth(280)
  frame:SetHeight(36 + table.getn(CHECKBOXES) * 26 + table.getn(SLIDERS) * 44 + 60)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  frame:SetFrameStrata("DIALOG")
  frame:SetToplevel(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:SetClampedToScreen(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function() this:StartMoving() end)
  frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
  })
  frame:Hide()
  table.insert(UISpecialFrames, "InkmapOptionsFrame")
  self.frame = frame

  local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOP", frame, "TOP", 0, -16)
  title:SetText("Inkmap " .. Inkmap.version)

  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)

  self.checks = {}
  for i, info in ipairs(CHECKBOXES) do
    self.checks[i] = CreateCheckbox(frame, i, info)
  end

  local sliderTop = -36 - table.getn(CHECKBOXES) * 26 - 20
  self.sliders = {}
  for i, info in ipairs(SLIDERS) do
    self.sliders[i] = CreateSlider(frame, i, info, sliderTop)
  end

  local reset = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  reset:SetWidth(120)
  reset:SetHeight(22)
  reset:SetPoint("BOTTOM", frame, "BOTTOM", 0, 18)
  reset:SetText("Reset map")
  reset:SetScript("OnClick", function() Inkmap.window:Reset() end)

  frame:SetScript("OnShow", function() M:Refresh() end)
end

function M:Refresh()
  if not self.frame or not self.frame:IsShown() then return end
  local db = Inkmap.db
  for _, check in ipairs(self.checks) do
    check:SetChecked(db[check.info.key] and 1 or nil)
  end
  self.updating = true
  for _, slider in ipairs(self.sliders) do
    local value = db[slider.info.key]
    slider:SetValue(value)
    getglobal(slider:GetName() .. "Text"):SetText(SliderText(slider.info, value))
  end
  self.updating = false
end

function M:Toggle()
  if not self.frame then self:Create() end
  if self.frame:IsShown() then self.frame:Hide() else self.frame:Show() end
end
