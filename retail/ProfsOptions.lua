-- File: ProfsOptions.lua
-- Author      : Thal
-- Optimized   : 10/05/2026

-- Ensure SavedVariables table exists
S_ProfessionDB = S_ProfessionDB or {}

-- Table to hold all dynamic options
local optionsList = {}

-- Create the main options frame
local OptionsFrame = CreateFrame("Frame", "MyProfsOptionsFrame", UIParent, "BackdropTemplate")
OptionsFrame:SetSize(300, 150)
OptionsFrame:SetPoint("CENTER")
OptionsFrame:SetFrameStrata("DIALOG")
OptionsFrame:SetToplevel(true)
OptionsFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile=true, tileSize=32, edgeSize=32,
    insets={left=11, right=12, top=12, bottom=11}
})
OptionsFrame:SetMovable(true)
OptionsFrame:EnableMouse(true)
OptionsFrame:RegisterForDrag("LeftButton")
OptionsFrame:SetScript("OnDragStart", OptionsFrame.StartMoving)
OptionsFrame:SetScript("OnDragStop", OptionsFrame.StopMovingOrSizing)
OptionsFrame:Hide()

-- Title
local title = OptionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", OptionsFrame, "TOP", 0, -10)
title:SetText("Professions Viewer Options")

-- Close button
local closeBtn = CreateFrame("Button", nil, OptionsFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", OptionsFrame, "TOPRIGHT", -5, -5)
closeBtn:SetScript("OnClick", function() OptionsFrame:Hide() end)

-- Container for content
local contentFrame = CreateFrame("Frame", nil, OptionsFrame)
contentFrame:SetPoint("TOPLEFT", OptionsFrame, "TOPLEFT", 15, -40)
contentFrame:SetWidth(OptionsFrame:GetWidth()-30)
contentFrame:SetHeight(OptionsFrame:GetHeight()-50)

-- Vertical spacing
local yOffset = 0

-- Toggle button (show/hide frame)
local toggleBtn = CreateFrame("Button", "MyProfsToggleButton", UIParent, "UIPanelButtonTemplate")
toggleBtn:SetSize(100, 25)
toggleBtn:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
toggleBtn:SetText("Professions")
toggleBtn:SetMovable(true)
toggleBtn:EnableMouse(true)
toggleBtn:RegisterForDrag("LeftButton")
toggleBtn:SetScript("OnDragStart", function(self) self:StartMoving() end)
toggleBtn:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
-- toggleBtn:SetScript("OnClick", function() MyProfs_ToggleFrame() end)
toggleBtn:SetScript("OnClick", function()
	if ProfessionsFrame and ProfessionsFrame:IsVisible() then
		C_TradeSkillUI.CloseTradeSkill()
	end

	-- Safely pick profession 1 or 2
	local p1, p2 = GetProfessions()
	local p = IsAltKeyDown() and p2 or p1
	local id = p and select(7, GetProfessionInfo(p))

	if id then
		C_TradeSkillUI.OpenTradeSkill(id)
		C_TradeSkillUI.CloseTradeSkill()
	end
	MyProfs_ToggleFrame()
end)

-- Function to add a checkbox
local function AddCheckboxOption(label, settingKey, onChangeFunc)
    local check = CreateFrame("CheckButton", nil, contentFrame, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, yOffset)
    check.text:SetText(label)

    if S_ProfessionDB[settingKey] == nil then
        S_ProfessionDB[settingKey] = false
    end
    check:SetChecked(S_ProfessionDB[settingKey])

    check:SetScript("OnClick", function(self)
        local val = self:GetChecked()
        S_ProfessionDB[settingKey] = val
        if onChangeFunc then onChangeFunc(val) end
    end)

    table.insert(optionsList, {type="checkbox", check=check, key=settingKey, callback=onChangeFunc})
    yOffset = yOffset - 30

    local totalHeight = math.abs(yOffset) + 40
    contentFrame:SetHeight(totalHeight)
    OptionsFrame:SetHeight(totalHeight + 50)
end

-- Function to add radio-button options
local function AddRadioOption(label, settingKey, options)
    -- Label
    local lbl = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, yOffset)
    lbl:SetText(label)
    yOffset = yOffset - 20

    -- Initialize saved value if nil
    if S_ProfessionDB[settingKey] == nil then
        if settingKey == "realmSetting" and options[1] == "Current Realm" then
            S_ProfessionDB[settingKey] = "Current Realm"
        else
            S_ProfessionDB[settingKey] = options[1]
        end
    end

    local radioButtons = {}
    for _, val in ipairs(options) do
        local btn = CreateFrame("CheckButton", nil, contentFrame, "UICheckButtonTemplate")
        btn:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, yOffset)
        btn.text:SetText(val)

        -- Initial checked state
        btn:SetChecked(S_ProfessionDB[settingKey] == val)

        -- OnClick: save value
        btn:SetScript("OnClick", function()
            S_ProfessionDB[settingKey] = val
            for _, b in pairs(radioButtons) do
                b:SetChecked(b == btn)
            end
        end)

        radioButtons[val] = btn
        yOffset = yOffset - 25
    end

    table.insert(optionsList, {type="radio", key=settingKey, buttons=radioButtons})

    local totalHeight = math.abs(yOffset) + 40
    contentFrame:SetHeight(totalHeight)
    OptionsFrame:SetHeight(totalHeight + 50)
end

-- Show/hide toggle button
AddCheckboxOption("Show button", "showButton", function(val)
    if toggleBtn then
        if val then toggleBtn:Show() else toggleBtn:Hide() end
    end
end)

-- Show/hide Reload UI button
AddCheckboxOption("Show Reload Button", "showReloadButton", function(val)
    if reloadBtn then
        if val then reloadBtn:Show() else reloadBtn:Hide() end
    end
end)

-- Faction setting
AddRadioOption("Faction Display:", "factionSetting", {"Current Faction", "Both"})

-- Realm setting
AddRadioOption("Realm Display:", "realmSetting", {"Current Realm", "All"})

-- Tier setting
AddRadioOption("Default Tier:", "tierSetting", {"Midnight", "Base"})

-- Database Buttons (Backup / Cleanup / Restore)
local function AddDatabaseButtons()
    local btnWidth, btnHeight = 120, 25
    local xOffset = 0
    local yStart = yOffset - 10

    -- Backup DB
    local backupBtn = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
    backupBtn:SetSize(btnWidth, btnHeight)
    backupBtn:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", xOffset, yStart)
    backupBtn:SetText("Backup DB")
    backupBtn:SetScript("OnClick", function()
        StaticPopupDialogs["MYPROFS_BACKUP_CONFIRM"] = {
            text = "Do you want to backup the database?",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                CharBackupDB = {
                    Horde = H_ProfessionsDB,
                    Alliance = A_ProfessionsDB
                }
                print("|cff00ff00[MyProfs]|r Database backed up successfully!")
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("MYPROFS_BACKUP_CONFIRM")
    end)

    -- Cleanup DB
    local cleanupBtn = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
    cleanupBtn:SetSize(btnWidth, btnHeight)
    cleanupBtn:SetPoint("TOPLEFT", backupBtn, "BOTTOMLEFT", 0, -5)
    cleanupBtn:SetText("Cleanup DB")
    cleanupBtn:SetScript("OnClick", function()
        StaticPopupDialogs["MYPROFS_CLEANUP_CONFIRM"] = {
            text = "Do you want to clean all character databases? This cannot be undone.",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                H_ProfessionsDB = {}
                A_ProfessionsDB = {}
                print("|cff00ff00[MyProfs]|r All databases cleaned!")
				if ProfsFrame and ProfsFrame:IsShown() then BuildCharacterTable() end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("MYPROFS_CLEANUP_CONFIRM")
    end)

    -- Restore Backup
    local restoreBtn = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
    restoreBtn:SetSize(btnWidth, btnHeight)
    restoreBtn:SetPoint("TOPLEFT", cleanupBtn, "BOTTOMLEFT", 0, -5)
    restoreBtn:SetText("Restore Backup")
    restoreBtn:SetScript("OnClick", function()
        if not CharBackupDB then
            print("|cffff0000[MyProfs]|r No backup found!")
            return
        end
        StaticPopupDialogs["MYPROFS_RESTORE_CONFIRM"] = {
            text = "Do you want to restore the backup database?",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                H_ProfessionsDB = CharBackupDB.Horde or {}
                A_ProfessionsDB = CharBackupDB.Alliance or {}
                print("|cff00ff00[MyProfs]|r Database restored from backup!")
                if ProfsFrame and ProfsFrame:IsShown() then BuildCharacterTable() end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("MYPROFS_RESTORE_CONFIRM")
    end)

    -- Adjust vertical spacing
    yOffset = yOffset - (btnHeight*3 + 15)
    local totalHeight = math.abs(yOffset) + 40
    contentFrame:SetHeight(totalHeight)
    OptionsFrame:SetHeight(totalHeight + 50)
end

-- Add database buttons to the options frame
AddDatabaseButtons()

-- Apply saved settings on addon load
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "MyProfessions" then
        for _, entry in ipairs(optionsList) do
            if entry.type == "checkbox" then
                local saved = S_ProfessionDB[entry.key]
                entry.check:SetChecked(saved)
                if entry.callback then entry.callback(saved) end
            elseif entry.type == "radio" then
                local saved = S_ProfessionDB[entry.key]
                for val, btn in pairs(entry.buttons) do
                    btn:SetChecked(saved == val)
                end
            end
        end

        -- Toggle button visibility
        if S_ProfessionDB["showButton"] then toggleBtn:Show() else toggleBtn:Hide() end

        -- Reload UI button visibility
        if reloadBtn then
            if S_ProfessionDB["showReloadButton"] then reloadBtn:Show() else reloadBtn:Hide() end
        end
    end
end)

-- Slash command
SLASH_MYPROFSOPTIONS1 = "/profsoptions"
SlashCmdList["MYPROFSOPTIONS"] = function()
    if OptionsFrame:IsShown() then
        OptionsFrame:Hide()
    else
        OptionsFrame:Show()
    end
end

-- End of File: ProfsOptions.lua