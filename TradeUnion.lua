local addonName, addon = ...
TradeUnion = addon

-- Binding Strings
_G.BINDING_NAME_TRADEUNION_OPEN = "Open"

local function IsKeyMatch(pressedKey, binding)
    if not binding then return false end

    local modifiers = ""
    local key = binding

    local lastDash = binding:match("^.*()-")
    if lastDash then
        modifiers = binding:sub(1, lastDash - 1)
        key = binding:sub(lastDash + 1)
    end

    if pressedKey ~= key then return false end

    local isAlt = modifiers:find("ALT")
    local isCtrl = modifiers:find("CTRL")
    local isShift = modifiers:find("SHIFT")

    if (isAlt and not IsAltKeyDown()) or (not isAlt and IsAltKeyDown()) then return false end
    if (isCtrl and not IsControlKeyDown()) or (not isCtrl and IsControlKeyDown()) then return false end
    if (isShift and not IsShiftKeyDown()) or (not isShift and IsShiftKeyDown()) then return false end

    return true
end

local function InitHooks()
    for i = 1, NUM_CHAT_WINDOWS do
        local editBox = _G["ChatFrame"..i.."EditBox"]
        if editBox then
            local oldOnKeyDown = editBox:GetScript("OnKeyDown")
            editBox:SetScript("OnKeyDown", function(self, key)
                addon.suppressNextChar = false

                local b1, b2 = GetBindingKey("TRADEUNION_OPEN")
                if (b1 and IsKeyMatch(key, b1)) or (b2 and IsKeyMatch(key, b2)) then
                    addon:ToggleSearch()
                    addon.suppressNextChar = true
                    self:ClearFocus()
                    return
                end

                if oldOnKeyDown then oldOnKeyDown(self, key) end
            end)

            local oldOnChar = editBox:GetScript("OnChar")
            editBox:SetScript("OnChar", function(self, text)
                if addon.suppressNextChar then
                    addon.suppressNextChar = false
                    return
                end
                if oldOnChar then oldOnChar(self, text) end
            end)
        end
    end
end

-- Initialize SavedVariables
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        if not TradeUnionDB then
            TradeUnionDB = {}
        end
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        print("|cff00ff00TradeUnion|r loaded. Type /tu to open.")
        
        if not GetBindingKey("TRADEUNION_OPEN") then
            print("|cff00ff00TradeUnion|r: No hotkey bound. Please set a keybinding in the Key Bindings menu under 'Trade Union'.")
        end
        InitHooks()
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)

-- UI Constants
local SEARCH_RESULT_HEIGHT = 20
local MAX_RESULTS = 15

function addon:CreateGUI()
    local f = CreateFrame("Frame", "TradeUnionFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    f:SetSize(300, 400)
    f:SetPoint("BOTTOMLEFT", ChatFrame1, "TOPLEFT", 0, 20)
    f:Hide()

    -- Background
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    -- Search Box
    local eb = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    eb:SetSize(260, 30)
    eb:SetPoint("BOTTOM", f, "BOTTOM", 0, 20)
    eb:SetAutoFocus(true)
    eb:SetScript("OnEscapePressed", function()
        f:Hide()
        self:SetText("")
        addon:UpdateSearch("")
    end)
    eb:SetScript("OnTextChanged", function(self)
        addon:UpdateSearch(self:GetText())
    end)
    eb:SetScript("OnArrowPressed", function(self, key)
        addon:NavigateList(key)
    end)
    eb:SetScript("OnEnterPressed", function()
        addon:SelectCurrentResult()
    end)
    f.SearchBox = eb

    -- Results Container
    local results = CreateFrame("Frame", nil, f)
    results:SetWidth(260)
    results:SetPoint("BOTTOM", eb, "TOP", 0, 10)
    f.Results = results

    f.ResultButtons = {}

    addon.MainFrame = f
end

function addon:NavigateList(key)
    if not addon.currentResults or #addon.currentResults == 0 then return end

    if key == "UP" then
        addon.selectedIndex = addon.selectedIndex - 1
        if addon.selectedIndex < 1 then addon.selectedIndex = #addon.currentResults end
    elseif key == "DOWN" then
        addon.selectedIndex = addon.selectedIndex + 1
        if addon.selectedIndex > #addon.currentResults then addon.selectedIndex = 1 end
    end

    addon:UpdateHighlight()
end

function addon:UpdateSearch(text)
    local results = {}
    text = string.lower(text)

    if text ~= "" then
        for eng, cn in pairs(addon.Translations) do
            if string.find(string.lower(eng), text, 1, true) then
                table.insert(results, {eng = eng, cn = cn})
            end
        end

        table.sort(results, function(a, b) return a.eng < b.eng end)
    end

    addon.currentResults = results
    addon.selectedIndex = 1
    addon:DisplayResults(results)
end

function addon:DisplayResults(results)
    local f = addon.MainFrame

    -- Hide all existing buttons
    for _, btn in ipairs(f.ResultButtons) do
        btn:Hide()
    end

    for i, data in ipairs(results) do
        if i > MAX_RESULTS then break end

        local btn = f.ResultButtons[i]
        if not btn then
            btn = CreateFrame("Button", nil, f.Results)
            btn:SetSize(260, SEARCH_RESULT_HEIGHT)
            btn:SetPoint("TOPLEFT", f.Results, "TOPLEFT", 0, -(i-1)*SEARCH_RESULT_HEIGHT)

            local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            text:SetPoint("LEFT", btn, "LEFT", 5, 0)
            btn.Text = text

            btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")

            btn:SetScript("OnClick", function()
                addon:PasteText(data.cn)
            end)

            f.ResultButtons[i] = btn
        end

        btn.Text:SetText(data.eng .. " - " .. data.cn)
        btn:Show()
    end

    -- Adjust frame height based on results
    local numResults = math.min(#results, MAX_RESULTS)
    local listHeight = numResults * SEARCH_RESULT_HEIGHT
    f.Results:SetHeight(listHeight)

    local newHeight = listHeight + 80
    if numResults == 0 then
        newHeight = 70
    end
    f:SetHeight(newHeight)

    addon:UpdateHighlight()
end

function addon:SelectCurrentResult()
    if addon.currentResults and addon.selectedIndex and addon.currentResults[addon.selectedIndex] then
        addon:PasteText(addon.currentResults[addon.selectedIndex].cn)
    end
end

function addon:PasteText(text)
    addon.MainFrame:Hide()
    addon.MainFrame.SearchBox:SetText("")
    addon:UpdateSearch("")

    local editBox = addon.lastActiveChatBox
    if not editBox then
        editBox = ChatEdit_GetActiveWindow()
    end

    if editBox then
        if not editBox:IsVisible() then
            editBox:Show()
        end
        editBox:SetFocus()

        local currentText = editBox:GetText()
        if currentText and currentText ~= "" and string.sub(currentText, -1) ~= " " then
            text = " " .. text
        end
        editBox:Insert(text)
    else
        ChatFrame_OpenChat(text)
    end
    addon.lastActiveChatBox = nil
end

function addon:UpdateHighlight()
    local f = addon.MainFrame
    for i, btn in ipairs(f.ResultButtons) do
        if i == addon.selectedIndex then
            btn:LockHighlight()
        else
            btn:UnlockHighlight()
        end
    end
end

function addon:ToggleSearch()
    if not addon.MainFrame then
        addon:CreateGUI()
    end

    if addon.MainFrame:IsShown() then
        addon.MainFrame:Hide()
    else
        local editBox = ChatEdit_GetActiveWindow()
        if editBox and editBox:IsVisible() then
            addon.lastActiveChatBox = editBox
        else
            addon.lastActiveChatBox = nil
        end

        addon.MainFrame:Show()
        addon.MainFrame.SearchBox:SetText("")
        addon:UpdateSearch("")
        C_Timer.After(0.05, function()
            if addon.MainFrame:IsShown() then
                addon.MainFrame.SearchBox:SetFocus()
                addon.MainFrame.SearchBox:SetText("")
            end
        end)
    end
end

-- Slash Command
SLASH_TRADEUNION1 = "/tu"
SLASH_TRADEUNION2 = "/tradeunion"
SlashCmdList["TRADEUNION"] = function(msg)
    addon:ToggleSearch()
end
