local addonName, addon = ...
TradeUnion = addon

-- Binding Strings
_G.BINDING_NAME_TRADEUNION_OPEN = "Open"

StaticPopupDialogs["TRADEUNION_RESET_CONFIRM"] = {
    text = "Are you sure you want to reset all translations to default? This cannot be undone.",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        TradeUnionDB.translations = {}
        if addon.Translations then
            for k, v in pairs(addon.Translations) do
                TradeUnionDB.translations[k] = v
            end
        end
        print("|cff00ff00TradeUnion|r: Translations reset to default.")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

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

local function CreateKeyChord(key)
    if key:find("SHIFT") or key:find("CTRL") or key:find("ALT") then
        return nil
    end

    local chord = ""
    if IsAltKeyDown() then chord = chord .. "ALT-" end
    if IsControlKeyDown() then chord = chord .. "CTRL-" end
    if IsShiftKeyDown() then chord = chord .. "SHIFT-" end
    chord = chord .. key
    return chord
end

local function InitHooks()
    for i = 1, NUM_CHAT_WINDOWS do
        local editBox = _G["ChatFrame"..i.."EditBox"]
        if editBox then
            local oldOnKeyDown = editBox:GetScript("OnKeyDown")
            editBox:SetScript("OnKeyDown", function(self, key)
                self.suppressNextChar = false
                self.restoreText = false

                local b1, b2 = GetBindingKey("TRADEUNION_OPEN")
                local chord = CreateKeyChord(key)
                local action = chord and GetBindingAction(chord)

                if (b1 and IsKeyMatch(key, b1)) or (b2 and IsKeyMatch(key, b2)) or (action == "TRADEUNION_OPEN") then
                    addon:ToggleSearch()
                    self.suppressNextChar = true
                    self.preSuppressText = self:GetText()
                    self.preSuppressCursor = self:GetCursorPosition()
                    return
                end

                if oldOnKeyDown then oldOnKeyDown(self, key) end
            end)

            local oldOnChar = editBox:GetScript("OnChar")
            editBox:SetScript("OnChar", function(self, text)
                if self.suppressNextChar then
                    self.suppressNextChar = false
                    self.restoreText = true
                    return
                end
                if oldOnChar then oldOnChar(self, text) end
            end)

            local oldOnTextChanged = editBox:GetScript("OnTextChanged")
            editBox:SetScript("OnTextChanged", function(self, userInput)
                if self.restoreText then
                    self.restoreText = false
                    self:SetText(self.preSuppressText)
                    self:SetCursorPosition(self.preSuppressCursor)
                    return
                end

                if addon.MainFrame and addon.MainFrame:IsShown() then
                    local text = self:GetText()
                    local cursor = self:GetCursorPosition()

                    if userInput and addon.searchStartIndex and cursor < addon.searchStartIndex then
                        addon.MainFrame:Hide()
                    else
                        local start = addon.searchStartIndex or 1
                        local query = string.sub(text, start, cursor)
                        addon:UpdateSearch(query)
                    end
                end
                if oldOnTextChanged then oldOnTextChanged(self, userInput) end
            end)

            local oldOnArrowPressed = editBox:GetScript("OnArrowPressed")
            editBox:SetScript("OnArrowPressed", function(self, key)
                if addon.MainFrame and addon.MainFrame:IsShown() then
                    if key == "UP" or key == "DOWN" then
                        addon:NavigateList(key)
                        return
                    end
                end
                if oldOnArrowPressed then oldOnArrowPressed(self, key) end
            end)

            local oldOnEnterPressed = editBox:GetScript("OnEnterPressed")
            editBox:SetScript("OnEnterPressed", function(self)
                if addon.MainFrame and addon.MainFrame:IsShown() and addon.currentResults and #addon.currentResults > 0 then
                    addon:SelectCurrentResult()
                    return
                end
                if oldOnEnterPressed then oldOnEnterPressed(self) end
            end)

            local oldOnEscapePressed = editBox:GetScript("OnEscapePressed")
            editBox:SetScript("OnEscapePressed", function(self)
                if addon.MainFrame and addon.MainFrame:IsShown() and addon.currentResults and #addon.currentResults > 0 then
                    addon.MainFrame:Hide()
                    return
                end
                if oldOnEscapePressed then oldOnEscapePressed(self) end
            end)

            local oldOnEditFocusLost = editBox:GetScript("OnEditFocusLost")
            editBox:SetScript("OnEditFocusLost", function(self)
                if addon.MainFrame and addon.MainFrame:IsShown() and not addon.MainFrame:IsMouseOver() then
                    addon.MainFrame:Hide()
                end
                if oldOnEditFocusLost then oldOnEditFocusLost(self) end
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
        if not TradeUnionDB.translations then
            TradeUnionDB.translations = {}
        end

        -- Merge defaults
        if addon.Translations then
            for k, v in pairs(addon.Translations) do
                if not TradeUnionDB.translations[k] then
                    TradeUnionDB.translations[k] = v
                end
            end
        end

        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        print("|cff00ff00TradeUnion|r loaded. Type /tu to list commands.")

        if not GetBindingKey("TRADEUNION_OPEN") then
            print("|cff00ff00TradeUnion|r: No hotkey bound. Please set a keybinding in the Key Bindings menu under 'Trade Union'.")
        end
        InitHooks()
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)

-- UI Constants
local SEARCH_RESULT_HEIGHT = 20
local MAX_RESULTS = 6

function addon:CreateGUI()
    local f = CreateFrame("Frame", "TradeUnionFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    f:SetSize(320, 400)
    f:SetPoint("BOTTOMLEFT", ChatFrame1, "TOPLEFT", 0, 20)
    f:Hide()

    -- Background
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    -- Results ScrollFrame
    local sf = CreateFrame("ScrollFrame", "TradeUnionResultsScrollFrame", f, "UIPanelScrollFrameTemplate")
    sf:SetPoint("BOTTOM", f, "BOTTOM", 0, 10)
    sf:SetPoint("TOP", f, "TOP", 0, -10)
    sf:SetWidth(285)
    f.ScrollFrame = sf

    -- Results Container
    local results = CreateFrame("Frame", nil, sf)
    results:SetSize(260, 1)
    sf:SetScrollChild(results)
    f.Results = results
    f.ResultButtons = {}

    local noRes = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    noRes:SetPoint("CENTER", f, "CENTER", 0, 0)
    noRes:SetWidth(240)
    noRes:SetJustifyH("CENTER")
    noRes:Hide()
    f.NoResultsText = noRes

    addon.MainFrame = f
end

function addon:NavigateList(key)
    if not addon.currentResults or #addon.currentResults == 0 then return end

    if key == "UP" then
        if addon.selectedIndex > 1 then
            addon.selectedIndex = addon.selectedIndex - 1
        end
    elseif key == "DOWN" then
        if addon.selectedIndex < #addon.currentResults then
            addon.selectedIndex = addon.selectedIndex + 1
        end
    end

    addon:UpdateHighlight()

    -- Scroll to selection
    local parent = addon.MainFrame.ScrollFrame
    local height = SEARCH_RESULT_HEIGHT
    local offset = (addon.selectedIndex - 1) * height

    local currentScroll = parent:GetVerticalScroll()
    local viewHeight = parent:GetHeight()

    if offset < currentScroll then
        parent:SetVerticalScroll(offset)
    elseif (offset + height) > (currentScroll + viewHeight) then
        parent:SetVerticalScroll(offset + height - viewHeight)
    end
end

local function HighlightText(text, searchTerms)
    if not searchTerms or #searchTerms == 0 then return text end

    local lowerText = string.lower(text)
    local ranges = {}

    for _, term in ipairs(searchTerms) do
        local startIdx = 1
        while true do
            local s, e = string.find(lowerText, term, startIdx, true)
            if not s then break end
            table.insert(ranges, {s, e})
            startIdx = e + 1
        end
    end

    if #ranges == 0 then return text end

    table.sort(ranges, function(a, b) return a[1] < b[1] end)

    local merged = {}
    local current = ranges[1]

    for i = 2, #ranges do
        local nextRange = ranges[i]
        if nextRange[1] <= current[2] + 1 then
            current[2] = math.max(current[2], nextRange[2])
        else
            table.insert(merged, current)
            current = nextRange
        end
    end
    table.insert(merged, current)

    local res = ""
    local lastPos = 1
    for _, r in ipairs(merged) do
        res = res .. string.sub(text, lastPos, r[1] - 1)
        res = res .. "|cff00ff00" .. string.sub(text, r[1], r[2]) .. "|r"
        lastPos = r[2] + 1
    end
    res = res .. string.sub(text, lastPos)

    return res
end

local function CalculateScore(text, searchTerms)
    local score = 0
    local lowerText = string.lower(text)
    local totalMatchLength = 0

    for _, term in ipairs(searchTerms) do
        local startIdx = string.find(lowerText, term, 1, true)
        if not startIdx then return -1 end

        totalMatchLength = totalMatchLength + #term
        if startIdx == 1 then score = score + 50 end
    end

    score = score + 100
    score = score - (#text - totalMatchLength)

    return score
end

function addon:UpdateSearch(text)
    local results = {}
    text = string.lower(text)

    local searchTerms = {}
    for word in text:gmatch("%S+") do
        table.insert(searchTerms, word)
    end

    if #searchTerms > 0 then
        local source = TradeUnionDB.translations or addon.Translations
        for eng, cn in pairs(source) do
            local score = CalculateScore(eng, searchTerms)
            if score > -1 then
                table.insert(results, {eng = eng, cn = cn, score = score})
            end
        end

        table.sort(results, function(a, b)
            if a.score ~= b.score then
                return a.score < b.score
            end
            return a.eng > b.eng
        end)
    end

    addon.currentResults = results
    addon.selectedIndex = #results
    addon:DisplayResults(results, searchTerms)
end

function addon:DisplayResults(results, searchTerms)
    local f = addon.MainFrame

    -- Hide all existing buttons
    for _, btn in ipairs(f.ResultButtons) do
        btn:Hide()
    end

    local numResults = #results
    if numResults == 0 then
        f.ScrollFrame:Hide()
        local term = table.concat(searchTerms, " ")
        if term and term ~= "" then
            f.NoResultsText:SetText("No translation found for " .. term)
        else
            f.NoResultsText:SetText("Start typing...")
        end
        f.NoResultsText:Show()
        f:SetHeight(40)
        addon:UpdateHighlight()
        return
    end

    f.NoResultsText:Hide()
    f.ScrollFrame:Show()

    for i, data in ipairs(results) do
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

        local displayEng = HighlightText(data.eng, searchTerms)
        btn.Text:SetText(displayEng .. " - " .. data.cn)
        btn:Show()
    end

    -- Adjust frame height based on results
    local listHeight = numResults * SEARCH_RESULT_HEIGHT
    f.Results:SetHeight(listHeight)

    local visibleCount = math.min(numResults, MAX_RESULTS)

    local visibleHeight = visibleCount * SEARCH_RESULT_HEIGHT
    f.ScrollFrame:SetHeight(visibleHeight)

    local scrollBar = _G["TradeUnionResultsScrollFrameScrollBar"]
    if scrollBar then
        if numResults > MAX_RESULTS then
            scrollBar:Show()
        else
            scrollBar:Hide()
        end
    end

    local newHeight = visibleHeight + 20
    f:SetHeight(newHeight)

    local maxScroll = math.max(0, listHeight - visibleHeight)
    f.ScrollFrame:SetVerticalScroll(maxScroll)

    addon:UpdateHighlight()
end

function addon:SelectCurrentResult()
    if addon.currentResults and addon.selectedIndex and addon.currentResults[addon.selectedIndex] then
        addon:PasteText(addon.currentResults[addon.selectedIndex].cn)
    end
end

function addon:PasteText(text)
    addon.MainFrame:Hide()

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
        local cursor = editBox:GetCursorPosition()
        local startIdx = addon.searchStartIndex or 1

        local prefix = string.sub(currentText, 1, startIdx - 1)
        prefix = string.gsub(prefix, "%s+$", "")
        local suffix = string.sub(currentText, cursor + 1)
        local newText = prefix .. text .. suffix

        editBox:SetText(newText)
        editBox:SetCursorPosition(#prefix + #text)
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

function addon:GetSearchStart(text, cursor)
    if cursor == 0 then return 1 end
    local prefix = string.sub(text, 1, cursor)
    local lastSpace = string.match(prefix, ".*()%s")
    if lastSpace then
        return lastSpace + 1
    else
        return 1
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

            local text = editBox:GetText()
            local cursor = editBox:GetCursorPosition()
            addon.searchStartIndex = addon:GetSearchStart(text, cursor)

            addon.MainFrame:ClearAllPoints()
            addon.MainFrame:SetPoint("BOTTOMLEFT", editBox, "TOPLEFT", 0, 0)

            addon.MainFrame:Show()

            local query = string.sub(text, addon.searchStartIndex, cursor)
            addon:UpdateSearch(query)
        end
    end
end

function addon:ExportTranslations()
    local export = "addon.Translations = {\n"
    local keys = {}
    local source = TradeUnionDB.translations or addon.Translations
    for k in pairs(source) do table.insert(keys, k) end
    table.sort(keys)

    for _, k in ipairs(keys) do
        export = export .. string.format('    ["%s"] = "%s",\n', k, source[k])
    end
    export = export .. "}"
    addon:ShowExportWindow(export)
end

function addon:ShowExportWindow(text)
    if not addon.ExportFrame then
        local f = CreateFrame("Frame", "TradeUnionExportFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
        f:SetSize(500, 400)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:EnableMouse(true)

        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })

        local sf = CreateFrame("ScrollFrame", "TradeUnionExportScroll", f, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT", 20, -20)
        sf:SetPoint("BOTTOMRIGHT", -40, 20)

        local eb = CreateFrame("EditBox", nil, sf)
        eb:SetMultiLine(true)
        eb:SetFontObject(ChatFontNormal)
        eb:SetWidth(440)
        sf:SetScrollChild(eb)

        eb:SetScript("OnEscapePressed", function() f:Hide() end)

        f.EditBox = eb
        f.ScrollFrame = sf

        local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)

        addon.ExportFrame = f
    end

    addon.ExportFrame:Show()
    addon.ExportFrame.EditBox:SetText(text)
    addon.ExportFrame.EditBox:HighlightText()
    addon.ExportFrame.EditBox:SetFocus()
end

function addon:ShowImportWindow()
    if not addon.ImportFrame then
        local f = CreateFrame("Frame", "TradeUnionImportFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
        f:SetSize(500, 400)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:EnableMouse(true)

        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })

        local sf = CreateFrame("ScrollFrame", "TradeUnionImportScroll", f, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT", 20, -20)
        sf:SetPoint("BOTTOMRIGHT", -40, 50)

        local eb = CreateFrame("EditBox", nil, sf)
        eb:SetMultiLine(true)
        eb:SetFontObject(ChatFontNormal)
        eb:SetWidth(440)
        sf:SetScrollChild(eb)

        eb:SetScript("OnEscapePressed", function() f:Hide() end)

        f.EditBox = eb

        local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)

        local importBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        importBtn:SetSize(100, 30)
        importBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 15)
        importBtn:SetText("Import")
        importBtn:SetScript("OnClick", function()
            addon:ProcessImport(f.EditBox:GetText())
            f:Hide()
        end)

        addon.ImportFrame = f
    end

    addon.ImportFrame:Show()
    addon.ImportFrame.EditBox:SetText("")
    addon.ImportFrame.EditBox:SetFocus()
end

function addon:ProcessImport(text)
    local count = 0
    for eng, cn in text:gmatch('%["(.-)"%]%s*=%s*"(.-)"') do
        if eng and cn then
            if not TradeUnionDB.translations then TradeUnionDB.translations = {} end
            TradeUnionDB.translations[eng] = cn
            count = count + 1
        end
    end

    if count > 0 then
        print("|cff00ff00TradeUnion|r: Successfully imported " .. count .. " translations.")
    else
        print("|cff00ff00TradeUnion|r: No valid translations found. Ensure format is: [\"English\"] = \"Chinese\",")
    end
end

local function FindKeyCI(tbl, key)
    if not tbl then return nil end
    if tbl[key] then return key end
    key = string.lower(key)
    for k in pairs(tbl) do
        if string.lower(k) == key then
            return k
        end
    end
    return nil
end

-- Slash Command
SLASH_TRADEUNION1 = "/tu"
SLASH_TRADEUNION2 = "/tradeunion"
SlashCmdList["TRADEUNION"] = function(msg)
    local cmd, rest = msg:match("^(%S*)%s*(.-)$")
    cmd = string.lower(cmd)
    if cmd == "add" then
        local eng, cn

        -- Check if starts with quote
        if rest:sub(1,1) == '"' then
            -- Match quoted string followed by space and rest
            eng, cn = rest:match('^"(.-)"%s+(.+)$')
        else
            -- Match first word followed by space and rest
            eng, cn = rest:match("^(%S+)%s+(.+)$")
        end

        -- If cn is found, check if it is fully quoted and strip
        if cn then
            local quoted_cn = cn:match('^"(.-)"$')
            if quoted_cn then cn = quoted_cn end
        end

        if eng and cn then
            if not TradeUnionDB.translations then TradeUnionDB.translations = {} end
            local key = FindKeyCI(TradeUnionDB.translations, eng) or eng
            TradeUnionDB.translations[key] = cn
            print("|cff00ff00TradeUnion|r: Added translation: " .. key .. " -> " .. cn)
        else
            print("|cff00ff00TradeUnion|r: Usage: /tu add {english} {chinese}")
        end
    elseif cmd == "remove" then
        local eng = rest
        -- Strip quotes if present
        local quoted = eng:match('^"(.-)"$')
        if quoted then eng = quoted end

        if eng and eng ~= "" then
            local key = FindKeyCI(TradeUnionDB.translations, eng)
            if key then
                TradeUnionDB.translations[key] = nil
                print("|cff00ff00TradeUnion|r: Removed translation: " .. key)
            else
                print("|cff00ff00TradeUnion|r: Translation not found: " .. eng)
            end
        else
            print("|cff00ff00TradeUnion|r: Usage: /tu remove {english}")
        end
    elseif cmd == "export" then
        addon:ExportTranslations()
    elseif cmd == "import" then
        addon:ShowImportWindow()
    elseif cmd == "reset" then
        StaticPopup_Show("TRADEUNION_RESET_CONFIRM")
    elseif cmd == "open" then
        addon:ToggleSearch()
    else
        print("|cff00ff00TradeUnion|r Commands:")
        print("  /tu open - Open search window. Prefer setting a keybinding.")
        print("  /tu add English 英语 - Add translation")
        print("  /tu remove English - Add translation for \"English\"")
        print("  /tu export - Export translations")
        print("  /tu import - Import translations")
        print("  /tu reset - Reset translations to default")
    end
end
