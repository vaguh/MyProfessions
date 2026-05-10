-- File: ProfsView.lua
-- Author      : Thal
-- Optimized   : 8/31/2025

-- Addon version
ProfsView_Version = "1.0"

-- Global SavedVariables
H_ProfessionsDB = H_ProfessionsDB or {}
A_ProfessionsDB = A_ProfessionsDB or {}

-- Reset function
local function ResetDatabases()
    H_ProfessionsDB = {}
    A_ProfessionsDB = {}
    print("MyProfs: All character databases have been reset!")
end

-- debug mode
local DEBUG = false
local function dbg(msg)
    if DEBUG then print(msg) end
end

dbg("ProfsView.lua loaded")

-- Slash command for reset
SLASH_MYPROFSRESET1 = "/myprofsreset"
SlashCmdList["MYPROFSRESET"] = function(msg)
    ResetDatabases()
end

local retryCount = 0
local maxRetries = 5

local function UpdateCharacterInfo()
	dbg("UpdateCharacterInfo running")
    local charName = UnitName("player")
    local charRealm = GetRealmName()
    local uniqueID = charName .. " - " .. charRealm
    local level = UnitLevel("player")
    local restedXP = GetXPExhaustion() or 0
    local maxXP = UnitXPMax("player") or 0
    local isResting = IsResting()
    local _, class = UnitClass("player")
    local faction = UnitFactionGroup("player") -- always "Alliance" or "Horde" in English
    local gender = (UnitSex("player") == 2) and "male" or "female" -- sexIndex = 2 voor male, 3 voor female
    local _, raceFileName = UnitRace("player")
    local race = raceFileName

    -- Scan faction
    if not faction then
        if retryCount < maxRetries then
            retryCount = retryCount + 1
            print("|cffff0000[MyProfs DEBUG]|r Faction not ready for " .. uniqueID ..
                  " (attempt " .. retryCount .. "/" .. maxRetries .. "), retrying...")
            C_Timer.After(1, UpdateCharacterInfo)
        else
            print("|cffff0000[MyProfs DEBUG]|r Faction STILL nil after " .. maxRetries ..
                  " tries for " .. uniqueID .. ". Skipping.")
        end
        return
    end

    retryCount = 0 -- reset once we succeed

    -- Scan professions
    local profs = {}
    for i = 1, GetNumSkillLines() do
        local skillName, _, _, skillRank = GetSkillLineInfo(i)
        if skillName and skillName ~= "Racial" and skillName ~= "Languages" then
            table.insert(profs, {name = skillName, rank = skillRank})
        end
    end

    -- Get gold
    local money = GetMoney()  -- amount in copper
    local gold = math.floor(money / 10000)  -- convert to gold

    local charData = {
        uniqueID = uniqueID,
        charName = charName,
        charRealm = charRealm,
        level = level,
        class = class,
        profs = profs,
        faction = faction,
		gold = gold,
        restedXP = restedXP,
        maxXP = maxXP,
        isResting = IsResting(),
        gender = gender,
        race = race,
    }

    -- Get existing DB entry (if it already exists)
    local charEntry
    if faction == "Horde" then
        charEntry = H_ProfessionsDB[uniqueID]
    elseif faction == "Alliance" then
        charEntry = A_ProfessionsDB[uniqueID]
    end

    -- Preserve old visibility setting if available
    if charEntry and charEntry.visibility then
        charData.visibility = charEntry.visibility
    else
        charData.visibility = "Shown"  -- default for new characters
    end

    if faction == "Horde" then
        H_ProfessionsDB[uniqueID] = charData
    elseif faction == "Alliance" then
        A_ProfessionsDB[uniqueID] = charData
    end
end

-- Event frame for login, level-ups, and profession updates
local eventFrame = CreateFrame("Frame")
dbg("EventFrame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
dbg("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
dbg("PLAYER_LEVEL_UP")
eventFrame:RegisterEvent("SKILL_LINES_CHANGED")
dbg("SKILL_LINES_CHANGED")
eventFrame:RegisterEvent("AUCTION_HOUSE_CLOSED")
dbg("AUCTION_HOUSE_CLOSED")
eventFrame:RegisterEvent("PLAYER_XP_UPDATE")
dbg("PLAYER_XP_UPDATE")
eventFrame:RegisterEvent("TRADE_SKILL_UPDATE")
dbg("TRADE_SKILL_UPDATE")

eventFrame:SetScript("OnEvent", function(self, event, ...)
	dbg("Event fired: " .. event)
    if event == "PLAYER_LOGIN" then
        UpdateCharacterInfo()
        print("MyProfs v" .. ProfsView_Version .. " loaded!")
    elseif event == "PLAYER_LEVEL_UP" then
        UpdateCharacterInfo()
        local newLevel = ...
        print("Level up! " .. UnitName("player") .. " is now level " .. newLevel)
    else
        -- Profession or gold events
        UpdateCharacterInfo()
        if ProfsFrame and ProfsFrame:IsShown() then BuildCharacterTable() end
    end
end)


-- End of File: ProfsView.lua