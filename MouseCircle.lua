local ADDON_NAME = ...

local addon = CreateFrame("Frame")
addon:RegisterEvent("ADDON_LOADED")
addon:RegisterEvent("PLAYER_LOGIN")

local db
local config = _G.MouseCircleConfig or {}
local defaultColor = config.circleColor or {}
local defaults = {
  enabled = true,
  size = config.circleSize or 64,
  color = {
    r = defaultColor.r or 1,
    g = defaultColor.g or 1,
    b = defaultColor.b or 1,
    a = defaultColor.a or 1,
  },
}

local function Print(message)
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99" .. ADDON_NAME .. "|r: " .. message)
end

local function EnsureCircleFrame()
  if addon.circleFrame then
    return
  end

  local frame = CreateFrame("Frame", nil, UIParent)
  frame:SetFrameStrata("TOOLTIP")
  frame:EnableMouse(false)
  frame:Hide()

  local texture = frame:CreateTexture(nil, "OVERLAY")
  texture:SetAllPoints()
  texture:SetTexture("Interface\\Minimap\\Ping\\ping4")
  texture:SetBlendMode("ADD")
  frame.texture = texture

  frame:SetScript("OnUpdate", function(self)
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
  end)

  addon.circleFrame = frame
end

local function ApplySettings()
  EnsureCircleFrame()
  local color = db.color or defaults.color

  addon.circleFrame:SetSize(db.size, db.size)
  addon.circleFrame.texture:SetVertexColor(color.r, color.g, color.b, color.a)

  if db.enabled then
    addon.circleFrame:Show()
  else
    addon.circleFrame:Hide()
  end
end

local function CreateLabeledSlider(parent, labelText, minValue, maxValue, step, xOffset, yOffset)
  local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  label:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, yOffset)
  label:SetText(labelText)

  local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
  slider:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -8)
  slider:SetPoint("RIGHT", parent, "RIGHT", -24, 0)
  slider:SetMinMaxValues(minValue, maxValue)
  slider:SetValueStep(step)
  slider:SetObeyStepOnDrag(true)

  local sliderName = slider:GetName()
  local low
  local high
  local text
  if sliderName then
    low = _G[sliderName .. "Low"]
    high = _G[sliderName .. "High"]
    text = _G[sliderName .. "Text"]
  end
  if low then
    low:SetText(tostring(minValue))
  end
  if high then
    high:SetText(tostring(maxValue))
  end
  if text then
    text:SetText("")
  end

  slider.valueText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  slider.valueText:SetPoint("TOPRIGHT", slider, "TOPRIGHT", 0, 16)

  return slider
end

local function RefreshConfigUI()
  if not addon.configFrame then
    return
  end

  local color = db.color or defaults.color
  
  addon.configFrame:SetSize(360, 400)
  addon.configFrame.sizeSlider:SetValue(db.size)
  addon.configFrame.sizeSlider.valueText:SetText(string.format("%d", db.size))

  addon.configFrame.rSlider:SetValue(color.r)
  addon.configFrame.gSlider:SetValue(color.g)
  addon.configFrame.bSlider:SetValue(color.b)
  addon.configFrame.aSlider:SetValue(color.a)

  addon.configFrame.rSlider.valueText:SetText(string.format("%.2f", color.r))
  addon.configFrame.gSlider.valueText:SetText(string.format("%.2f", color.g))
  addon.configFrame.bSlider.valueText:SetText(string.format("%.2f", color.b))
  addon.configFrame.aSlider.valueText:SetText(string.format("%.2f", color.a))

end

local function EnsureConfigFrame()
  if addon.configFrame then
    return
  end

  local frame = CreateFrame("Frame", "MouseCircleConfigFrame", UIParent, "BasicFrameTemplateWithInset")
  frame:SetSize(360, 360)
  frame:SetPoint("CENTER")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:Hide()

  frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 8, 0)
  frame.title:SetText("Mouse Circle Configuration")

  local sizeSlider = CreateLabeledSlider(frame, "Size", 16, 256, 1, 16, -40)
  sizeSlider:SetScript("OnValueChanged", function(self, value)
    local rounded = math.floor(value + 0.5)
    if db.size ~= rounded then
      db.size = rounded
      self.valueText:SetText(string.format("%d", rounded))
      ApplySettings()
    end
  end)
  frame.sizeSlider = sizeSlider

  local function CreateColorHandler(channel, slider)
    slider:SetScript("OnValueChanged", function(self, value)
      local rounded = math.floor((value * 100) + 0.5) / 100
      if db.color[channel] ~= rounded then
        db.color[channel] = rounded
        self.valueText:SetText(string.format("%.2f", rounded))
        ApplySettings()
      end
    end)
  end

  local rSlider = CreateLabeledSlider(frame, "Red", 0, 1, 0.01, 16, -115)
  local gSlider = CreateLabeledSlider(frame, "Green", 0, 1, 0.01, 16, -180)
  local bSlider = CreateLabeledSlider(frame, "Blue", 0, 1, 0.01, 16, -245)
  local aSlider = CreateLabeledSlider(frame, "Alpha", 0, 1, 0.01, 16, -310)
  frame.rSlider = rSlider
  frame.gSlider = gSlider
  frame.bSlider = bSlider
  frame.aSlider = aSlider

  CreateColorHandler("r", rSlider)
  CreateColorHandler("g", gSlider)
  CreateColorHandler("b", bSlider)
  CreateColorHandler("a", aSlider)


  addon.configFrame = frame
end

local function OpenConfig()
  EnsureConfigFrame()
  RefreshConfigUI()
  addon.configFrame:Show()
  addon.configFrame:Raise()
end

addon:SetScript("OnEvent", function(_, event, loadedName)
  if event == "ADDON_LOADED" and loadedName == ADDON_NAME then
    MouseCircleDB = MouseCircleDB or {}
    db = MouseCircleDB

    for key, value in pairs(defaults) do
      if db[key] == nil then
        if type(value) == "table" then
          db[key] = {}
          for innerKey, innerValue in pairs(value) do
            db[key][innerKey] = innerValue
          end
        else
          db[key] = value
        end
      end
    end

    if db.color == nil then
      db.color = {
        r = defaults.color.r,
        g = defaults.color.g,
        b = defaults.color.b,
        a = db.alpha or defaults.color.a,
      }
    else
      for channel, channelDefault in pairs(defaults.color) do
        if db.color[channel] == nil then
          db.color[channel] = channelDefault
        end
      end
    end

    db.alpha = nil
  elseif event == "PLAYER_LOGIN" then
    ApplySettings()
    Print("Loaded. Use /mc to toggle and /mc config to customize.")
  end
end)

SLASH_MOUSECIRCLE1 = "/mc"
SlashCmdList.MOUSECIRCLE = function(msg)
  local command = (msg and msg:match("^%s*(.-)%s*$") or ""):lower()

  if command == "config" then
    OpenConfig()
    return
  end

  db.enabled = not db.enabled
  ApplySettings()
  Print(db.enabled and "Cursor circle enabled." or "Cursor circle disabled.")
end
