-- File: ProfsFrame.lua
-- Author      : Thal
-- Optimized   : 8/31/2025 (updated for options panel control)


-- Constants
local ROW_HEIGHT = 20
local HEADER_HEIGHT = 30
local COLUMN_PADDING = 5
local MAX_PLAYER_LEVEL = 90

-- Helpers
local primaryProfessions = {
    Alchemy=true, Blacksmithing=true, Enchanting=true, Engineering=true,
    Herbalism=true, Inscription=true, Jewelcrafting=true, Leatherworking=true,
    Tailoring=true, Mining=true, Skinning=true
}

local primaryPriority = {
    Mining = 1,          -- Column 1 (most common, fuels BS/Eng/JC)
    Herbalism = 2,       -- Column 1 (fuels Alchemy/Inscription)
    Alchemy = 3,         -- Column 1 (high demand consumables)
    Blacksmithing = 4,   -- Column 2 (synergy with Mining)
    Engineering = 5,     -- Column 2 (synergy with Mining)
    Jewelcrafting = 6,   -- Column 2 (synergy with Mining)
    Leatherworking = 7,  -- Column 1 (medium common)
    Skinning = 8,        -- Column 2 (synergy with LW)
    Tailoring = 9,       -- Column 1 (less common primary)
    Enchanting = 10,     -- Column 2 (standalone/complementary)
    Inscription = 11     -- Column 2 (synergy with Herbalism)
}

-- WoW class colors (MoP era table)
local CLASS_COLORS = {
    DEATHKNIGHT = {0.77, 0.12, 0.23},
    DRUID     = {1.0, 0.49, 0.04},
    HUNTER    = {0.67, 0.83, 0.45},
    MAGE      = {0.41, 0.8, 0.94},
    MONK      = {0.0, 1.0, 0.59},
    PALADIN   = {0.96, 0.55, 0.73},
    PRIEST    = {1.0, 1.0, 1.0},
    ROGUE     = {1.0, 0.96, 0.41},
    SHAMAN    = {0.0, 0.44, 0.87},
    WARLOCK   = {0.58, 0.51, 0.79},
    WARRIOR   = {0.78, 0.61, 0.43},
}

-- Map race+gender naar texture
local raceGenderMap = {
	male = {
		BloodElf   = "Interface\\CharacterFrame\\TemporaryPortrait-Male-BloodElf",
		Draenei    = "Interface\\CharacterFrame\\TemporaryPortrait-Male-Draenei",
		Dwarf      = "Interface\\CharacterFrame\\TemporaryPortrait-Male-Dwarf",
		Gilnean    = "Interface\\CharacterFrame\\TemporaryPortrait-Male-Gilnean",
		Gnome      = "Interface\\CharacterFrame\\TemporaryPortrait-Male-Gnome",
		Goblin     = "Interface\\CharacterFrame\\TemporaryPortrait-Male-Goblin",
		Human      = "Interface\\CharacterFrame\\TemporaryPortrait-Male-Human",
		NightElf   = "Interface\\CharacterFrame\\TemporaryPortrait-Male-NightElf",
		Orc        = "Interface\\CharacterFrame\\TemporaryPortrait-Male-Orc",
		Pandaren   = "Interface\\CharacterFrame\\TemporaryPortrait-Male-Pandaren",
		Scourge    = "Interface\\CharacterFrame\\TemporaryPortrait-Male-Scourge",
		Tauren     = "Interface\\CharacterFrame\\TemporaryPortrait-Male-Tauren",
		Troll      = "Interface\\CharacterFrame\\TemporaryPortrait-Male-Troll",
		Worgen     = "Interface\\CharacterFrame\\TemporaryPortrait-Male-Worgen",
	},
	female = {
		BloodElf   = "Interface\\CharacterFrame\\TemporaryPortrait-Female-BloodElf",
		Draenei    = "Interface\\CharacterFrame\\TemporaryPortrait-Female-Draenei",
		Dwarf      = "Interface\\CharacterFrame\\TemporaryPortrait-Female-Dwarf",
		Gilnean    = "Interface\\CharacterFrame\\TemporaryPortrait-Female-Gilnean",
		Gnome      = "Interface\\CharacterFrame\\TemporaryPortrait-Female-Gnome",
		Goblin     = "Interface\\CharacterFrame\\TemporaryPortrait-Female-Goblin",
		Human      = "Interface\\CharacterFrame\\TemporaryPortrait-Female-Human",
		NightElf   = "Interface\\CharacterFrame\\TemporaryPortrait-Female-NightElf",
		Orc        = "Interface\\CharacterFrame\\TemporaryPortrait-Female-Orc",
		Pandaren   = "Interface\\CharacterFrame\\TemporaryPortrait-Female-Pandaren",
		Scourge    = "Interface\\CharacterFrame\\TemporaryPortrait-Female-Scourge",
		Tauren     = "Interface\\CharacterFrame\\TemporaryPortrait-Female-Tauren",
		Troll      = "Interface\\CharacterFrame\\TemporaryPortrait-Female-Troll",
		Worgen     = "Interface\\CharacterFrame\\TemporaryPortrait-Female-Worgen",
	}
}

-- Header indicator function
local function UpdateHeaderIndicators()
    for _, col in ipairs(ProfsFrame.columnFrames) do
        local arrow = col.fontString.arrowTexture
        if arrow then
            if col.key == ProfsFrame.sortColumn then
                arrow:Show()
                if ProfsFrame.sortAscending then
                    arrow:SetTexCoord(0,1,0,1)   -- normal up arrow
                else
                    arrow:SetTexCoord(0,1,1,0)   -- flip down
                end
            else
                arrow:Hide()
            end
        end
    end
end

-- Format numbers with "." as thousands separator
local function FormatNumber(num)
    if not num then return "0" end
    local formatted = tostring(num)
	local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1.%2")
        if k == 0 then break end
    end
    return formatted
end

-- Return faction color
local function GetFactionColor(faction)
    if faction=="Alliance" then
        return 0,0.44,1
    elseif faction=="Horde" then
        return 1,0,0
    else
        return 1,1,0 -- Neutral / Both
    end
                
end

-- Frame initialization
function ProfsFrame_OnLoad()
    ProfsFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile=true, tileSize=32, edgeSize=32,
        insets={left=11,right=12,top=12,bottom=11}
    })
    ProfsFrame:SetMovable(true)
    ProfsFrame:EnableMouse(true)
    ProfsFrame:RegisterForDrag("LeftButton")
    ProfsFrame:SetScript("OnDragStart", ProfsFrame.StartMoving)
    ProfsFrame:SetScript("OnDragStop", ProfsFrame.StopMovingOrSizing)
    ProfsFrame:Hide()

    tinsert(UISpecialFrames, "ProfsFrame")  -- ESC will close this frame

    -- Reload UI button (bottom center of main frame)
    reloadBtn = CreateFrame("Button", "MyProfsReloadButton", ProfsFrame, "UIPanelButtonTemplate")
    reloadBtn:SetSize(100, 25)
    reloadBtn:SetPoint("BOTTOM", ProfsFrame, "BOTTOM", 0, 15)
    reloadBtn:SetText("Reload UI")
    reloadBtn:SetMovable(false)
    reloadBtn:EnableMouse(true)
    reloadBtn:SetScript("OnClick", function() ReloadUI() end)

	ProfsFrame:SetScript("OnHide", function()
		if ProfsFrame.rowContextMenu then
			ProfsFrame.rowContextMenu:Hide()
		end
		if ProfsFrame.rowContextMenuCatcher then
			ProfsFrame.rowContextMenuCatcher:Hide()
		end
		activeDropdown = nil
	end)	
end

-- Create reusable title buttons
local function CreateTitleButton(parent, size, point, texture, tooltip, onClick, iconScale)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(unpack(size))
    btn:SetPoint(unpack(point))
    if texture then
        local icon = btn:CreateTexture(nil, "ARTWORK")
        local scale = iconScale or 1
        icon:SetSize(size[1]*scale, size[2]*scale)
        icon:SetPoint("CENTER", btn, "CENTER")
        icon:SetTexture(texture)
        btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    end
    btn:SetScript("OnEnter", function() GameTooltip:SetOwner(btn,"ANCHOR_TOP"); GameTooltip:SetText(tooltip,1,1,1); GameTooltip:Show() end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    btn:SetScript("OnClick", onClick)
    return btn
end

-- Simple dropdown replacement (no UIDropDownMenu dependency)
local activeDropdown = nil  -- track which popup is open

local function CreateSimpleDropdown(parent, width, options, getSelected, onSelect)
    local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    popup:SetSize(width, #options * 22 + 8)
    popup:SetFrameStrata("TOOLTIP")
    popup:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile=true, tileSize=16, edgeSize=16,
        insets={left=4, right=4, top=4, bottom=4}
    })
    popup:Hide()

    for i, opt in ipairs(options) do
        local btn = CreateFrame("Button", nil, popup)
        btn:SetSize(width - 10, 20)
        btn:SetPoint("TOPLEFT", popup, "TOPLEFT", 5, -(i-1)*22 - 4)
        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetAllPoints()
        fs:SetJustifyH("LEFT")
        fs:SetText(opt)
        btn:SetScript("OnEnter", function()
            fs:SetTextColor(1, 1, 0)
        end)
        btn:SetScript("OnLeave", function()
            if opt == getSelected() then
                fs:SetTextColor(0, 1, 0)
            else
                fs:SetTextColor(1, 1, 1)
            end
        end)
        btn:SetScript("OnClick", function()
            onSelect(opt)
            popup:Hide()
            activeDropdown = nil
        end)
        -- store reference so we can refresh colors on open
        btn.fs = fs
        btn.opt = opt
        btn.getSelected = getSelected
    end

    -- Close if user clicks elsewhere
    popup:SetScript("OnHide", function()
        if activeDropdown == popup then activeDropdown = nil end
    end)

    popup.buttons = {popup:GetChildren()}
    return popup
end

-- Create a label+button pair that acts as a dropdown toggle
local function CreateDropdownToggle(parent, x, y, width, label, getSelected, popupRef)
    -- Label above / to left
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y + 14)
    lbl:SetText(label)
    lbl:SetTextColor(0.8, 0.8, 0.8)

    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width, 20)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    local function RefreshLabel()
        btn:SetText(getSelected())
    end
    RefreshLabel()

    btn:SetScript("OnClick", function()
        -- Refresh selection highlights each open
        for _, child in ipairs({popupRef[1]:GetChildren()}) do
            if child.fs and child.opt then
                if child.opt == getSelected() then
                    child.fs:SetTextColor(0, 1, 0)
                else
                    child.fs:SetTextColor(1, 1, 1)
                end
            end
        end

        if activeDropdown and activeDropdown ~= popupRef[1] then
            activeDropdown:Hide()
        end
        if popupRef[1]:IsShown() then
            popupRef[1]:Hide()
            activeDropdown = nil
        else
            popupRef[1]:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
            popupRef[1]:Show()
            activeDropdown = popupRef[1]
        end
    end)

    btn.RefreshLabel = RefreshLabel
    return btn
end

-- Define the popup once (outside of row loop, ideally at top of file)
StaticPopupDialogs["MYPROFS_DELETE_CONFIRM"] = {
    text = "Are you sure you want to delete this character?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self, data)
        -- data is the character table we pass in
        if data.faction == "Horde" then
            H_ProfessionsDB[data.uniqueID] = nil
        elseif data.faction == "Alliance" then
            A_ProfessionsDB[data.uniqueID] = nil
        end
		if ProfsFrame and ProfsFrame:IsShown() then BuildCharacterTable() end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Build/update character table
function BuildCharacterTable()

    -- ScrollFrame setup
    if not ProfsFrame.scrollFrame then
        local scroll = CreateFrame("ScrollFrame", nil, ProfsFrame, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", ProfsFrame, "TOPLEFT", 10, -60)
        scroll:SetPoint("BOTTOMRIGHT", ProfsFrame, "BOTTOMRIGHT", -30, 50)
        local child = CreateFrame("Frame", nil, scroll)
        child:SetPoint("TOPLEFT", scroll, "TOPLEFT")
        child:SetWidth(scroll:GetWidth())
        scroll:SetScrollChild(child)
        ProfsFrame.scrollFrame = scroll
        ProfsFrame.scrollChild = child
    end
    local scrollChild = ProfsFrame.scrollChild

    -- Clear previous rows
    ProfsFrame.rowObjects = ProfsFrame.rowObjects or {}
    for _, obj in ipairs(ProfsFrame.rowObjects) do obj:Hide() end
    ProfsFrame.rowObjects = {}
    
    -- Merge DBs
    local allDB = {}
    for k,v in pairs(H_ProfessionsDB or {}) do allDB[k]=v end
    for k,v in pairs(A_ProfessionsDB or {}) do allDB[k]=v end

    -- Title bar
    if not ProfsFrame.titleBar then
        local titleBar = CreateFrame("Frame", nil, ProfsFrame, "BackdropTemplate")
        titleBar:SetSize(ProfsFrame:GetWidth(), 34)
        titleBar:SetPoint("BOTTOM", ProfsFrame, "TOP")
        titleBar:SetBackdrop({
            edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize=16, tile=true, tileSize=32,
            insets={left=3,right=3,top=3,bottom=3}
        })
        titleBar:SetBackdropColor(0,0,0,0)
        titleBar:SetBackdropBorderColor(1,1,1,1)
        titleBar:EnableMouse(true)
        titleBar:RegisterForDrag("LeftButton")
        titleBar:SetScript("OnDragStart", function() ProfsFrame:StartMoving() end)
        titleBar:SetScript("OnDragStop", function() ProfsFrame:StopMovingOrSizing() end)

        local titleText = titleBar:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
        titleText:SetPoint("CENTER")
        titleText:SetText("Professions Viewer")
        titleText:SetTextColor(1,1,1)
        ProfsFrame.titleBar = titleBar
        ProfsFrame.headerText = titleText

        -- Buttons
		-- Options (cog) button opens dynamic options frame
        -- ProfsFrame.optionsButton = CreateTitleButton(titleBar,{28,28},{"TOPRIGHT",titleBar,"TOPRIGHT",-66,-2},"Interface\\Buttons\\UI-OptionsButton","Options",function() print("|cff00ff00[MyProfs]|r Options clicked!") end,0.5)
        ProfsFrame.optionsButton = CreateTitleButton(titleBar,{28,28},{"TOPRIGHT", titleBar, "TOPRIGHT",-66,-2},"Interface\\Buttons\\UI-OptionsButton","Options",function()
            if MyProfsOptionsFrame:IsShown() then
                MyProfsOptionsFrame:Hide()
            else
                MyProfsOptionsFrame:Show()
            end
        end,0.6)
        ProfsFrame.versionButton = CreateTitleButton(titleBar,{28,28},{"TOPRIGHT",titleBar,"TOPRIGHT",-36,-2},"Interface\\Icons\\INV_Misc_QuestionMark","Version",function() print("|cff00ff00[ProfsView]|r "..(ProfsView_Version or "?").." loaded!") end,0.6)
        ProfsFrame.closeButton = CreateTitleButton(titleBar,{28,28},{"TOPRIGHT",titleBar,"TOPRIGHT",-5,-2},"Interface\\Buttons\\UI-Panel-MinimizeButton-Up","Close",function() ProfsFrame:Hide() end,1)
    end

    -- Faction: Apply options panel selection (only once; do not overwrite user's in-frame choice)
    if ProfsFrame.selectedFaction == nil then
        local factionSetting = S_ProfessionDB["factionSetting"] or "Current Faction"
        if factionSetting == "Both" then
            ProfsFrame.selectedFaction = "Both"
        else
            ProfsFrame.selectedFaction = UnitFactionGroup("player")
        end
    end

    -- Get color for headers based on selected faction
    local r, g, b = GetFactionColor(ProfsFrame.selectedFaction)

    -- Faction dropdown
    if not ProfsFrame.factionDrop then
        local factionOptions = {"Both","Horde","Alliance"}
        local popupRef = {}
        popupRef[1] = CreateSimpleDropdown(
            ProfsFrame.titleBar, 100, factionOptions,
            function() return ProfsFrame.selectedFaction or "Both" end,
            function(val)
                ProfsFrame.selectedFaction = val
                ProfsFrame.factionToggle.RefreshLabel()
				if ProfsFrame and ProfsFrame:IsShown() then BuildCharacterTable() end
            end
        )
        ProfsFrame.factionToggle = CreateDropdownToggle(
            ProfsFrame.titleBar, 5, -7, 100,
            "Faction",
            function() return ProfsFrame.selectedFaction or "Both" end,
            popupRef
        )
        ProfsFrame.factionDrop = popupRef[1]
    else
        ProfsFrame.factionToggle.RefreshLabel()
    end

    -- Realm: Apply options panel selection (only once; do not overwrite user's in-frame choice)
	if ProfsFrame.selectedRealm == nil then
        local RealmSetting = S_ProfessionDB["realmSetting"] or "Current Realm"
        if RealmSetting == "All" then
            ProfsFrame.selectedRealm = "All"
        else
            ProfsFrame.selectedRealm = GetRealmName()
        end
    end
						
    -- Build realm list from DB
    local realmOptions = {"All"}
    local seen = {}

    for _, data in pairs(allDB) do
        if data.charRealm and not seen[data.charRealm] then
            table.insert(realmOptions, data.charRealm)
            seen[data.charRealm] = true
        end
    end

    -- Realm dropdown
    if not ProfsFrame.realmDrop then
        local popupRef = {}
        popupRef[1] = CreateSimpleDropdown(
            ProfsFrame.titleBar, 130, realmOptions,
            function() return ProfsFrame.selectedRealm or "All" end,
            function(val)
                ProfsFrame.selectedRealm = val
                ProfsFrame.realmToggle.RefreshLabel()
				if ProfsFrame and ProfsFrame:IsShown() then BuildCharacterTable() end
            end
        )
        ProfsFrame.realmToggle = CreateDropdownToggle(
            ProfsFrame.titleBar, 115, -7, 130,
            "Realm",
            function() return ProfsFrame.selectedRealm or "All" end,
            popupRef
        )
  
        ProfsFrame.realmDrop = popupRef[1]
        ProfsFrame.realmPopupRef = popupRef
    else
        ProfsFrame.realmToggle.RefreshLabel()
    end

    -- Visibility dropdown: Apply option "shown"
    if ProfsFrame.selectedVisibility == nil then
        ProfsFrame.selectedVisibility = "Shown"
    end

    -- Visibility dropdown
    if not ProfsFrame.visibilityDrop then
        local visibilityOptions = {"All", "Shown", "Hidden"}
        local popupRef = {}
        popupRef[1] = CreateSimpleDropdown(
            ProfsFrame.titleBar, 110, visibilityOptions,
            function() return ProfsFrame.selectedVisibility or "Shown" end,
            function(val)
                ProfsFrame.selectedVisibility = val
                ProfsFrame.visibilityToggle.RefreshLabel()
				if ProfsFrame and ProfsFrame:IsShown() then BuildCharacterTable() end
            end
        )
        ProfsFrame.visibilityToggle = CreateDropdownToggle(
            ProfsFrame.titleBar, 255, -7, 110,
            "Visibility",
            function() return ProfsFrame.selectedVisibility or "Shown" end,
            popupRef
        )
        ProfsFrame.visibilityDrop = popupRef[1]
    else
        ProfsFrame.visibilityToggle.RefreshLabel()
    end
    -- Columns
    local columns = {
        {name="Character", key="charName", width=100}, 
        {name="Lvl", key="level", width=75}, 
        {name="Class", key="class", width=100},
        {name="First\nProfession", key="prof1Str", width=135}, 
        {name="Second\nProfession", key="prof2Str", width=135},
        {name="Archaeology", key="archaeologyStr", width=120}, 
        {name="Fishing", key="fishingStr", width=120},
        {name="Cooking", key="cookingStr", width=120}, 
        {name="First Aid", key="firstAidStr", width=120}, 
        {name="Gold", key="goldStr", width=50}
    }
    ProfsFrame.columnFrames = ProfsFrame.columnFrames or {}
    local xStart = 20
    for i,col in ipairs(columns) do
        local f = ProfsFrame.columnFrames[i]
        local fs
        if f then 
            fs = f.fontString 
        else
            fs = ProfsFrame:CreateFontString(nil,"OVERLAY","GameFontNormal")
            fs:SetPoint("TOPLEFT", ProfsFrame,"TOPLEFT", xStart,-30)
            fs:SetWidth(col.width)
            fs:SetJustifyH("CENTER")

            local clickFrame = CreateFrame("Button", nil, ProfsFrame)
            clickFrame:SetPoint("TOPLEFT",ProfsFrame,"TOPLEFT",xStart,-30)
            clickFrame:SetSize(col.width, HEADER_HEIGHT)
            clickFrame:RegisterForClicks("LeftButtonUp")
            clickFrame:SetScript("OnClick", function()
                if ProfsFrame.sortColumn==col.key then 
                    ProfsFrame.sortAscending = not ProfsFrame.sortAscending
                else 
                    ProfsFrame.sortColumn=col.key
                    ProfsFrame.sortAscending=true 
                end
				if ProfsFrame and ProfsFrame:IsShown() then BuildCharacterTable() end
                UpdateHeaderIndicators()
            end)
			fs.clickFrame = clickFrame
            ProfsFrame.columnFrames[i]={fontString=fs,key=col.key,width=col.width}
        end

        -- HEADER COLOR: Keep original behavior using options panel selection
        local r,g,b = GetFactionColor(ProfsFrame.selectedFaction)

        -- fs:SetTextColor(r,g,b)
        fs:SetTextColor(1, 1, 0)
        fs:SetText(col.name)

        -- Create arrow texture for this header
        if not fs.arrowTexture then
            local arrow = fs.clickFrame:CreateTexture(nil, "OVERLAY")
            arrow:SetSize(16, 12)  -- size of the arrow
            arrow:SetPoint("LEFT", fs, "RIGHT", -7, 0)
            arrow:SetTexture("Interface\\Buttons\\UI-SortArrow")  -- built-in WoW arrow
            arrow:Hide()
            fs.arrowTexture = arrow
        end

        xStart = xStart + col.width
    end

    -- Merge DB and filter by options
    local filteredDB = {}
    for _, data in pairs(allDB) do
        if data then
            local facMatch = (ProfsFrame.selectedFaction == "Both") or (data.faction and string.upper(data.faction) == string.upper(ProfsFrame.selectedFaction))
            local realmMatch = (ProfsFrame.selectedRealm == "All") or (data.charRealm == ProfsFrame.selectedRealm)
            local visMatch = (ProfsFrame.selectedVisibility == "All") or (data.visibility == ProfsFrame.selectedVisibility)
            if facMatch and realmMatch and visMatch then
                local prof1, prof2, prof1Name, prof2Name, arch, fishing, cooking, firstAid
                local prof1Rank, prof2Rank, archRank, fishingRank, cookingRank, firstAidRank = 0,0,0,0,0,0
                if data.profs then
                    local primaryList = {}
                    for _, p in ipairs(data.profs) do
                        local rank = tonumber(p.rank) or 0
                        if rank > 0 and primaryProfessions[p.name] then
                            table.insert(primaryList, {name = p.name, rank = rank})
                        elseif rank > 0 then
                            if p.name == "Archaeology" then
                                arch = p.name.." ("..rank..")"

                                archRank = rank
                            elseif p.name == "Fishing" then
                                fishing = p.name.." ("..rank..")"
                                fishingRank = rank
                            elseif p.name == "Cooking" then
                                cooking = p.name.." ("..rank..")"
                                cookingRank = rank
                            elseif p.name == "First Aid" then
                                firstAid = p.name.." ("..rank..")"
                                firstAidRank = rank
                            end
                        end
                    end
                    table.sort(primaryList, function(a, b) return (primaryPriority[a.name] or 999) < (primaryPriority[b.name] or 999) end)
                    if #primaryList >= 1 then
                        prof1 = primaryList[1].name.." ("..primaryList[1].rank..")"
                        prof1Rank = primaryList[1].rank
                        prof1Name = primaryList[1].name
                    end
                    if #primaryList >= 2 then
                        prof2 = primaryList[2].name.." ("..primaryList[2].rank..")"
                        prof2Rank = primaryList[2].rank
                        prof2Name = primaryList[2].name
                    end
                end
                data.prof1Str = prof1 or "-"
                data.prof2Str = prof2 or "-"
                data.archaeologyStr = arch or "-"
                data.fishingStr = fishing or "-"
                data.cookingStr = cooking or "-"
                data.firstAidStr = firstAid or "-"

                data.prof1Rank = prof1Rank
                data.prof2Rank = prof2Rank
                data.archaeologyRank = archRank
                data.fishingRank = fishingRank
                data.cookingRank = cookingRank
                data.firstAidRank = firstAidRank

                data.prof1Name = prof1Name or ""
                data.prof2Name = prof2Name or ""

                data.goldStr = FormatNumber(data.gold)
                table.insert(filteredDB, data)
            end
        end
    end

    -- Sorting
    ProfsFrame.sortColumn = ProfsFrame.sortColumn or "charName"
    if ProfsFrame.sortAscending==nil then ProfsFrame.sortAscending=true end

    local rankColumnMap = {
        prof1Str       = "prof1Rank",
        prof2Str       = "prof2Rank",
        archaeologyStr = "archaeologyRank",
        fishingStr     = "fishingRank",
        cookingStr     = "cookingRank",
        firstAidStr    = "firstAidRank",
    }

    table.sort(filteredDB,function(a,b)
        if not a then return false end
        if not b then return true end
        local key = ProfsFrame.sortColumn
        local valA = a[key] or ""
        local valB = b[key] or ""

        -- Special rule: "-" should always be treated as "last"
        local isDashA = (valA == "-" or valA == "" or valA == nil)
        local isDashB = (valB == "-" or valB == "" or valB == nil)
        if isDashA and not isDashB then
            return false -- A is dash, goes after B
        elseif isDashB and not isDashA then
            return true -- B is dash, goes after A
        elseif isDashA and isDashB then
            return false -- both dashes, keep order
        end

        local rankKey = rankColumnMap[key]

        -- Special handling for prof1Str / prof2Str: sort by name (alpha) first, then by rank (numeric)
        if key == "prof1Str" or key == "prof2Str" then
            local nameKey = (key == "prof1Str") and "prof1Name" or "prof2Name"
            local nameA = (a[nameKey] or ""):lower()
            local nameB = (b[nameKey] or ""):lower()
            if nameA ~= nameB then
                if ProfsFrame.sortAscending then
                    return nameA < nameB
                else
                    return nameA > nameB
                end
            end
            -- names equal → fall back to rank
            valA = tonumber(a[rankKey]) or 0
            valB = tonumber(b[rankKey]) or 0
        elseif rankKey then
            valA = tonumber(a[rankKey]) or 0
            valB = tonumber(b[rankKey]) or 0
        elseif key=="level" then
            valA = tonumber(a.level) or 0
            valB = tonumber(b.level) or 0
        elseif key=="goldStr" then
            -- try numeric gold first, fallback to parsed goldStr
            valA = tonumber(a.gold) or tonumber((tostring(a.goldStr or "0"):gsub("%.",""))) or 0
            valB = tonumber(b.gold) or tonumber((tostring(b.goldStr or "0"):gsub("%.",""))) or 0
        else
            valA = tostring(valA):lower()
            valB = tostring(valB):lower()
        end

        if valA==valB then return false end
        if ProfsFrame.sortAscending then return valA<valB else return valA>valB end
    end)
    
    -- Draw rows
    local yOffset = 0

    -- Create a single dropdown menu frame for all rows
    -- Create reusable right-click context menu
    if not ProfsFrame.rowContextMenu then
        local menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        menu:SetSize(120, 3 * 22 + 8)
        menu:SetFrameStrata("TOOLTIP")
        menu:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile=true, tileSize=16, edgeSize=16,
            insets={left=4, right=4, top=4, bottom=4}
        })
        menu:Hide()

        local contextButtons = {}
        local labels = {"Show", "Hide", "Delete"}
        for i, label in ipairs(labels) do
            local btn = CreateFrame("Button", nil, menu)
            btn:SetSize(110, 20)
            btn:SetPoint("TOPLEFT", menu, "TOPLEFT", 5, -(i-1)*22 - 4)
            local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            fs:SetAllPoints()
            fs:SetJustifyH("LEFT")
            fs:SetText(label)
            btn:SetScript("OnEnter", function() fs:SetTextColor(1,1,0) end)
            btn:SetScript("OnLeave", function() fs:SetTextColor(1,1,1) end)
            btn.fs = fs
            contextButtons[i] = btn
        end

        -- Click-outside catcher
        local catcher = CreateFrame("Frame", nil, UIParent)
        catcher:SetAllPoints(UIParent)
        catcher:SetFrameStrata("FULLSCREEN_DIALOG")
        catcher:EnableMouse(true)
        catcher:Hide()
        catcher:SetScript("OnMouseDown", function()
            menu:Hide()
            catcher:Hide()
            activeDropdown = nil
        end)

        ProfsFrame.rowContextMenu = menu
        ProfsFrame.rowContextMenuCatcher = catcher
        ProfsFrame.contextButtons = contextButtons
    end

    local rowContextMenu = ProfsFrame.rowContextMenu
    local contextButtons = ProfsFrame.contextButtons
	

    -- Get current player info
    local playerID = UnitName("player") .. " - " .. GetRealmName()
    local playerFaction = UnitFactionGroup("player")

    for _, data in ipairs(filteredDB) do
        -- Create a container frame for the row
        local row = CreateFrame("Frame", nil, scrollChild)
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, yOffset)
        row:SetSize(ProfsFrame:GetWidth() - 40, ROW_HEIGHT)

        -- Permanent background for logged-in character
        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(row)
        if data.uniqueID == playerID then
            if playerFaction == "Alliance" then
                bg:SetColorTexture(0, 0, 1, 0.25) -- blue
            else
                bg:SetColorTexture(1, 0, 0, 0.25) -- red
            end
        else
            bg:SetColorTexture(0, 0, 0, 0)
        end
		
        -- Highlight texture (hidden by default)
        local highlight = row:CreateTexture(nil, "BACKGROUND")
        highlight:SetAllPoints(row)
        highlight:SetColorTexture(0.2, 0.6, 1, 0.2) -- light blue transparent
        highlight:Hide()

        -- Mouse enter/leave scripts (hover)
        row:EnableMouse(true)
        row:SetScript("OnEnter", function() highlight:Show() end)
        row:SetScript("OnLeave", function() highlight:Hide() end)

        -- Right-click context menu
        row:SetScript("OnMouseUp", function(self, button)
            if button == "RightButton" then
                local items = {
                    { text = "Show",   func = function()
                        data.visibility = "Shown"
                        if data.faction == "Horde" and H_ProfessionsDB[data.uniqueID] then
                            H_ProfessionsDB[data.uniqueID].visibility = "Shown"
                        elseif data.faction == "Alliance" and A_ProfessionsDB[data.uniqueID] then
                            A_ProfessionsDB[data.uniqueID].visibility = "Shown"
                        end
                        rowContextMenu:Hide()
						if ProfsFrame and ProfsFrame:IsShown() then BuildCharacterTable() end
                    end },
                    { text = "Hide",   func = function()
                        data.visibility = "Hidden"
                        if data.faction == "Horde" and H_ProfessionsDB[data.uniqueID] then
                            H_ProfessionsDB[data.uniqueID].visibility = "Hidden"
                        elseif data.faction == "Alliance" and A_ProfessionsDB[data.uniqueID] then
                            A_ProfessionsDB[data.uniqueID].visibility = "Hidden"
                        end
                        rowContextMenu:Hide()
						if ProfsFrame and ProfsFrame:IsShown() then BuildCharacterTable() end
                    end },
                    { text = "Delete", func = function()
                        rowContextMenu:Hide()
                        StaticPopup_Show("MYPROFS_DELETE_CONFIRM", nil, nil, data)
                    end }
                }
                -- Populate the reusable buttons
                for i, item in ipairs(items) do
                    contextButtons[i].fs:SetText(item.text)
                    contextButtons[i].fs:SetTextColor(1,1,1)
                    contextButtons[i]:SetScript("OnClick", item.func)
                    contextButtons[i]:Show()
                end
                -- Close any open dropdown first
                if activeDropdown and activeDropdown ~= rowContextMenu then
                    activeDropdown:Hide()
                end
                rowContextMenu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT",
                    select(1, GetCursorPosition()) / UIParent:GetEffectiveScale(),
                    select(2, GetCursorPosition()) / UIParent:GetEffectiveScale() + rowContextMenu:GetHeight()
                )
				rowContextMenu:Show()
				activeDropdown = rowContextMenu
				ProfsFrame.rowContextMenuCatcher:Show()
            end
        end)

        -- Create text cells inside the row
        local xOffset = 0
        for _, col in ipairs(ProfsFrame.columnFrames) do
            local val = data[col.key] or "-"
            local cell = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            cell:SetPoint("LEFT", row, "LEFT", xOffset, 0)
            cell:SetWidth(col.width)
            cell:SetJustifyH("LEFT")
            cell:SetText(val)

            -- faction coloring for charName when "Both" selected
            if col.key=="charName" then
                if data.faction=="Alliance" then
                    cell:SetTextColor(0,0.44,1) -- Blue
                elseif data.faction=="Horde" then
                    cell:SetTextColor(1,0,0) -- Red
                else
                    cell:SetTextColor(1,1,1)
                end

                -- Set icon left of text
				local raceGenderTex = row:CreateTexture(nil, "ARTWORK")
                raceGenderTex:SetSize(16,16)
                raceGenderTex:SetPoint("RIGHT", cell, "LEFT", -2, 0)
                local texPath = "Interface\\CharacterFrame\\TempPortrait" -- default icon

                -- Voeg gender + race icon toe links van de naam
                if data.gender and data.race then

                    -- overwrite if valid
                    local t = raceGenderMap[data.gender] and raceGenderMap[data.gender][data.race]
                    if t then texPath = t end
                end
                raceGenderTex:SetTexture(texPath)
            elseif col.key=="class" then
                local color = CLASS_COLORS[(data.class or ""):upper()]
                if color then
                    cell:SetTextColor(unpack(color))
                else
                    cell:SetTextColor(1,1,1)
                end
            elseif col.key=="level" then
                local lvl = data.level or "-"
                local rested = tonumber(data.restedXP or 0) or 0
                local maxXP = tonumber(data.maxXP or 0) or 0
                
                local maxRested
                if (data.class or ""):upper() == "MONK" then
                    maxRested = maxXP * 3.0   -- Monk Enlightenment (300%)
                else
                    maxRested = maxXP * 1.5   -- Normal 150%
                end

                local missingRestedXP = maxRested - rested
                if missingRestedXP < 0 then missingRestedXP = 0 end

                local hoursToFull = 0
                local restRate
				local isResting = data.isResting
				if isResting then
					restRate = 0.05
				else
					restRate = 0.025
				end
				local status = isResting and "In City" or "Outside"

                if missingRestedXP > 0 then
                    -- 5% of XP per 8 hours (logged out)
                    hoursToFull = (missingRestedXP / (maxXP * restRate)) * 8
                    hoursToFull = math.ceil(hoursToFull)
                end

                -- Calculate days and hours from hoursToFull
                local days = math.floor(hoursToFull / 24)
                local hours = hoursToFull % 24

                local timeStr
                if days > 0 then
                    timeStr = days .. "d " .. hours .. "h"
                else
                    timeStr = hours .. "h"
                end

                if rested > 0 and maxXP > 0 and lvl < MAX_PLAYER_LEVEL then
					local percent = math.floor((rested / maxXP) * 100)
                    cell:SetText(lvl .. " (" .. percent .. "%)")
                    cell:SetTextColor(1,1,1)  -- force white

                    -- Only show tooltip if rested is not full
                    if missingRestedXP > 0 then
                        -- Tooltip for details
                        cell:EnableMouse(true)
                        cell:SetScript("OnEnter", function(self)
                            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                            GameTooltip:AddLine("Rested XP")
                            GameTooltip:AddDoubleLine("Amount:", FormatNumber(rested), 1,1,1, 0,1,0.5)
                            GameTooltip:AddDoubleLine("Percent:", percent .. "%", 1,1,1, 0,1,0.5)
                            GameTooltip:AddDoubleLine("full in:", timeStr.." ("..status..")", 1,1,1, 0.8,1,0.2)
                            GameTooltip:Show()
                        end)
                        cell:SetScript("OnLeave", function() GameTooltip:Hide() end)
					else
                        cell:EnableMouse(false) -- no tooltip when fully rested
                    end
                else
                    cell:SetText(lvl)
                end
			else
                cell:SetTextColor(1,1,1)
            end

            xOffset = xOffset + col.width
        end

		-- Optional horizontal divider line
		local hLine = row:CreateTexture(nil, "OVERLAY")
		hLine:SetColorTexture(0.5,0.5,0.5,1)
		hLine:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
		hLine:SetSize(row:GetWidth(), 1)
	
		-- Store the whole row object for later clearing
		table.insert(ProfsFrame.rowObjects, row)

		yOffset = yOffset - ROW_HEIGHT		
	end
	
    -- Calculate total gold
    local totalGold = 0
    for _, data in ipairs(filteredDB) do
        totalGold = totalGold + (tonumber(data.gold) or 0)
    end

	-- Create total fontstring once
	if not ProfsFrame.totalGoldText then
		ProfsFrame.totalGoldText = ProfsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		ProfsFrame.totalGoldText:SetPoint("BOTTOMRIGHT", ProfsFrame, "BOTTOMRIGHT", -40, 20)
	end
	
	-- Update text with coin icon
	local goldStr = FormatNumber(totalGold)
	ProfsFrame.totalGoldText:SetFormattedText("Total Gold: %s|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:0:0|t", goldStr)
	ProfsFrame.totalGoldText:SetTextColor(1, 0.82, 0) -- gold-like color
    
    scrollChild:SetHeight(-yOffset + 10)

end

-- Toggle frame
function MyProfs_ToggleFrame()
    if ProfsFrame:IsShown() then 
		ProfsFrame:Hide()
	else 
		BuildCharacterTable()
		ProfsFrame:Show() 
	end
end

-- Reload UI button
function Button2_OnClick()
    ReloadUI()
end

-- End of File: ProfsFrame.lua