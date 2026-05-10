-- File: ProfsView.lua
-- Author      : Thal
-- Optimized   : 10/05/2026

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

-- All professions skill ID's, on update needs checking
local ALL_PROF_SKILLLINES = {
   171, 2485, 2484, 2483, 2482, 2481, 2480, 2479, 2478, 2750, 2823, 2871, 2906, -- Alchemy
   164, 2477, 2476, 2475, 2474, 2473, 2472, 2454, 2437, 2751, 2822, 2872, 2907, -- Blacksmithing
   185, 2548, 2547, 2546, 2545, 2544, 2543, 2542, 2541, 2752, 2824, 2873, 2908, -- Cooking
   333, 2494, 2493, 2492, 2491, 2489, 2488, 2487, 2486, 2753, 2825, 2874, 2909, -- Enchanting
   202, 2506, 2505, 2504, 2503, 2502, 2501, 2500, 2499, 2755, 2827, 2875, 2910, -- Engineering
   356, 2592, 2591, 2590, 2589, 2588, 2587, 2586, 2585, 2754, 2826, 2876, 2911, -- Fishing
   182, 2556, 2555, 2554, 2553, 2552, 2551, 2550, 2549, 2760, 2832, 2877, 2912, -- Herbalism
   773, 2514, 2513, 2512, 2511, 2510, 2509, 2508, 2507, 2756, 2828, 2878, 2913, -- Inscription
   755, 2524, 2523, 2522, 2521, 2520, 2519, 2518, 2517, 2757, 2829, 2879, 2914, -- Jewelcrafting
   165, 2532, 2531, 2530, 2529, 2528, 2527, 2526, 2525, 2758, 2830, 2880, 2915, -- Leatherworking
   186, 2572, 2571, 2570, 2569, 2568, 2567, 2566, 2565, 2761, 2833, 2881, 2916, -- Mining
   393, 2564, 2563, 2562, 2561, 2560, 2559, 2558, 2557, 2762, 2834, 2882, 2917, -- Skinning
   197, 2540, 2539, 2538, 2537, 2536, 2535, 2534, 2533, 2759, 2831, 2883, 2918, -- Tailoring
   794, -- Archaeology
   129 -- First Aid
}

local tierOrder = {
    ["Classic"]        = 1,
    ["Outland"]        = 2,
    ["Northrend"]      = 3,
    ["Cataclysm"]      = 4,
    ["Pandaria"]       = 5,
    ["Draenor"]        = 6,
    ["Legion"]         = 7,
    ["Kul Tiran"]      = 8,
    ["Shadowlands"]    = 9,
    ["Dragon Isles"]   = 10,
    ["Khaz Algar"]     = 11,
    ["Midnight"]       = 12,
}

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

	-- Simple actual scan professions (retail-compatible, one tier only)
	local profsByBase = {}

	for _, id in ipairs(ALL_PROF_SKILLLINES) do
		local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(id)

		if info and info.professionName and info.skillLevel > 0 then
			local tier, prof = info.professionName:match("(.+)%s([^%s]+)$")
			if not tier then
				tier = "Base"
				prof = info.professionName
			end

			local baseID = info.parentProfessionID or id
			profsByBase[prof] = profsByBase[prof] or {
				base = prof,
				skillLine = baseID,
				tiers = {}
			}
		end
	end

	local profs = {}
	for _, p in pairs(profsByBase) do
		table.insert(profs, p)
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

-- function to load in all tiers and professions
local function UpdateProfessionTiers()
    local charName  = UnitName("player")
    local charRealm = GetRealmName()
    local uniqueID  = charName .. " - " .. charRealm
    local faction   = UnitFactionGroup("player")

    local db = (faction == "Horde") and H_ProfessionsDB or A_ProfessionsDB
    if not db or not db[uniqueID] then return end

    local charData = db[uniqueID]
    if not charData.profs then return end

    -- Build: tiersByBase[baseSkillLineID] = { {tier=..., rank=..., maxRank=..., id=...}, ... }
    local tiersByBase = {}
    local seenByBase  = {}

    for _, id in ipairs(ALL_PROF_SKILLLINES) do
        local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(id)
        if info and info.professionName then
            -- Determine "base" skillLine to attach this tier to.
            -- If the API provides parentProfessionID, use it; otherwise base is itself.
            local baseID = info.parentProfessionID or id
			

            tiersByBase[baseID] = tiersByBase[baseID] or {}
            seenByBase[baseID]  = seenByBase[baseID]  or {}

            -- Avoid duplicates
            if not seenByBase[baseID][id] then
                seenByBase[baseID][id] = true

                -- Split tier vs profession from name
                local tier, prof = info.professionName:match("(.+)%s([^%s]+)$")
                if not tier then
                    tier = "Base"
                    prof = info.professionName
                end

                -- Store tier info
                table.insert(tiersByBase[baseID], {
                    id      = id,
                    tier    = tier,
                    prof    = prof,
                    rank    = info.skillLevel or 0,
                    maxRank = info.maxSkillLevel or 0,
                })
            end
        end
    end

    -- Apply tiers to each profession entry on this character
    for _, p in ipairs(charData.profs) do
        if p.skillLine and tiersByBase[p.skillLine] and #tiersByBase[p.skillLine] > 0 then
            -- Convert to your expected structure
            local tiers = {}
            for _, t in ipairs(tiersByBase[p.skillLine]) do
                table.insert(tiers, {
                    tier    = t.tier,      -- "Dragon Isles", "Shadowlands", "Base", etc
                    rank    = t.rank,
                    maxRank = t.maxRank,
                    id      = t.id,        -- optional but useful
                })
            end
			table.sort(tiers, function(a, b)
				return (tierOrder[a.tier] or 999) < (tierOrder[b.tier] or 999)
			end)			

            p.tiers = tiers
        end
    end

    dbg("[MyProfs] Tiers updated for " .. uniqueID)
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
eventFrame:RegisterEvent("TRADE_SKILL_SHOW")
dbg("TRADE_SKILL_SHOW")

eventFrame:SetScript("OnEvent", function(self, event, ...)
	dbg("Event fired: " .. event)
    if event == "PLAYER_LOGIN" then
        print("MyProfs v" .. ProfsView_Version .. " loaded!")
    elseif event == "PLAYER_LEVEL_UP" then
        local newLevel = ...
        print("Level up! " .. UnitName("player") .. " is now level " .. newLevel)
        UpdateCharacterInfo()
		UpdateProfessionTiers()
    elseif event == "TRADE_SKILL_SHOW" or event == "SKILL_LINES_CHANGED" then -- this gets triggered by pressing professions button
		UpdateCharacterInfo()
		UpdateProfessionTiers()
		if ProfsFrame and ProfsFrame:IsShown() then BuildCharacterTable() end
	elseif event == "AUCTION_HOUSE_CLOSED" then
		UpdateCharacterInfo()  -- just save the data, no UI rebuild needed
	else
        -- Profession or gold events
        UpdateCharacterInfo()
        if ProfsFrame and ProfsFrame:IsShown() then BuildCharacterTable() end
    end
end)

-- End of File: ProfsView.lua