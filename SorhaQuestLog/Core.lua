SorhaQuestLog = LibStub("AceAddon-3.0"):NewAddon("SorhaQuestLog", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0", "LibSink-2.0")
local L = LibStub("AceLocale-3.0"):GetLocale("SorhaQuestLog")
SorhaQuestLog.L = L
 
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local LDB = LibStub:GetLibrary("LibDataBroker-1.1")
local SQLBroker = nil
SorhaQuestLog.SQLBroker = nil

-- local LBF = LibStub("LibButtonFacade", true)
local LBF = nil
local LBFGroup = nil

-- Used to stop the need to use self.db all the time
local db


-- Just bringing some frequently used global functions into local scope
local pairs = pairs
local tinsert = tinsert
local tContains = tContains
local tremove = tremove
local select = select
local format = format
local GetTime = GetTime
local _

-- Register framd font
LSM:Register("font", "framd", [[Interface\AddOns\SorhaQuestLog\Fonts\framd.ttf]])
LSM:Register("sound", "Peon Ready", [[Sound\Creature\Peon\PeonReady1.wav]])
LSM:Register("sound", "More work?", [[Sound\Creature\Peasant\PeasantWhat3.wav]])
LSM:Register("sound", "Work complete!", [[Sound\Creature\Peon\PeonBuildingComplete1.wav]])
LSM:Register("sound", "Quest Added", [[Sound\Interface\iQuestActivate.wav]])
LSM:Register("sound", "Quest Completed", [[Sound\Interface\iQuestComplete.wav]])
LSM:Register("sound", "Quest Failed", [[Sound\Interface\igQuestFailed.wav]])

-- Binding globals for bindings.xml
BINDING_HEADER_SORHAQUESTLOG = "Sorha Quest Log";
BINDING_NAME_TOGGLE_SORHAQUESTLOG = L["Toggle Minion"]

-- Frames
local tblLogButtonCache = {}
local tblStatusBarsCache = {}
local intNumberOfLogButtons = 0
local intNumberUsedStatusBars = 0

local strButtonPrefix = "SorhaQuestLogButton"
local strStatusBarPrefix = "SorhaQuestLogStatusBar"

-- Item button parts to use with LBF
local tblItemButtonLBFData = {
	Cooldown = false,
}


local dicOutlines = {
	[""] = L["None"],
	["OUTLINE"] = L["Outline"],
	["THICKOUTLINE"] = L["Thick Outline"],
}

local dicAutoHideOptions = {
	["Do Nothing"] = L["Do Nothing"],
	["Hide"] = L["Hide"],
	["Show"] = L["Show"],
}

-- Addon Setup
local defaults = {
	profile = {
		Modules = {
            ['*'] = true,
        },
		Main = {
			HideAll = false,
			HideBlizzardTracker = true,
			ShowHelpTooltips = true,
			ShowAnchors = false,
		},
		Fonts = {
		},
		Colours = {
		},
		AutoHide = {
			OnInstance = "Do Nothing",
			OnRaid = "Do Nothing",
			OnArena = "Do Nothing",
			OnBattleground = "Do Nothing",
			OnNormal = "Do Nothing",
			OnEnterCombat = "Do Nothing",
			OnLeaveCombat = "Do Nothing",
			OnEnterPetBattle = "Do Nothing",
			OnExitPetBattle = "Do Nothing",
		},
		ButtonSkins = {
			SkinID = "DreamLayout",
			Gloss = 0,
			Backdrop = false,
			Colors = {},
			SQLItemButtons = {
				SkinID = "DreamLayout",
				Gloss = 0,
				Backdrop = false,
				Colors = {},
			},
		},
	},
}

local options = nil
local moduleOptions = {}

local function getOptions()
	if not options then
		options = {
			type = "group",
			name = "SorhaQuestLog ".. "r106",
			handler = SorhaQuestLog,
			args = {
				General = {
					name = L["General Options"],
					type = "group",
					order = 1,
					args = {
						HideAll = {
							name = L["Hide All Sorha Quest Log"],
							desc = L["Hides all of Sorha Quest Log"],
							type = "toggle",
							width = "full",
							get = function() return db.Main.HideAll end,
							set = function()
								db.Main.HideAll = not db.Main.HideAll
								SorhaQuestLog:RefreshConfig(false)
							end,
							order = 1,
						},
						ShowAnchorsToggle = {
							name = L["Show minion anchors"],
							desc = L["Shows the anchors for minions to make them easier to move"],
							type = "toggle",
							width = "full",
							get = function() return db.Main.ShowAnchors end,
							set = function()
								db.Main.ShowAnchors = not db.Main.ShowAnchors
								SorhaQuestLog:RefreshConfig(false)
							end,
							order = 2,
						},
						ShowHelpTooltipsToggle = {
							name = L["Show helpful tooltips"],
							desc = L["Shows helpful tooltips for people learning the addon"],
							type = "toggle",
							width = "full",
							get = function() return db.Main.ShowHelpTooltips end,
							set = function()
								db.Main.ShowHelpTooltips = not db.Main.ShowHelpTooltips
							end,
							order = 3,
						},	
						HeaderBlizzardFrameSettingsSpacer = {
							name = "   ",
							width = "full",
							type = "description",
							order = 50,
						},
						HeaderBlizzardFrameSettings = {
							name = L["Blizzard Frame Settings"],
							type = "header",
							order = 51,
						},
						HideBlizzardTrackerToggle = {
							name = L["Hide the default quest tracker"],
							desc = L["Hides blizzards quest tracker.. which is also used for Achievement tracking"],
							type = "toggle",
							width = "full",
							get = function() return db.Main.HideBlizzardTracker end,
							set = function()
								db.Main.HideBlizzardTracker = not db.Main.HideBlizzardTracker
								SorhaQuestLog:HandleBlizzardTracker()
							end,
							order = 52,
						},	
						HeaderAutoHideSpacer = {
							name = "   ",
							width = "full",
							type = "description",
							order = 100,
						},
						HeaderAutoHide = {
							name = L["Auto Hide/Showing"],
							type = "header",
							order = 101,
						},
						OnInstanceAutoHideSelect = {
							name = L["When entering a Dungeon"],
							desc = L["What to do when entering a Dungeon"],
							type = "select",
							order = 102,
							values = dicAutoHideOptions,
							get = function() return db.AutoHide.OnInstance end,
							set = function(info, value)
								db.AutoHide.OnInstance = value
							end,
						},
						OnRaidAutoHideSelect = {
							name = L["When entering a Raid"],
							desc = L["What to do when entering a Raid"],
							type = "select",
							order = 103,
							values = dicAutoHideOptions,
							get = function() return db.AutoHide.OnRaid end,
							set = function(info, value)
								db.AutoHide.OnRaid = value
							end,
						},
						OnArenaAutoHideSelect = {
							name = L["When entering an Arena"],
							desc = L["What to do when entering an Arena"],
							type = "select",
							order = 104,
							values = dicAutoHideOptions,
							get = function() return db.AutoHide.OnArena end,
							set = function(info, value)
								db.AutoHide.OnArena = value
							end,
						},
						OnBattlegroundAutoHideSelect = {
							name = L["When entering a Battleground"],
							desc = L["What to do when entering a Battleground"],
							type = "select",
							order = 105,
							values = dicAutoHideOptions,
							get = function() return db.AutoHide.OnBattleground end,
							set = function(info, value)
								db.AutoHide.OnBattleground = value
							end,
						},
						OnNormalAutoHideSelect = {
							name = L["When entering normal world"],
							desc = L["What to do when entering an area that is not an Arena, Battleground, Dungeon or Raid"],
							type = "select",
							order = 106,
							values = dicAutoHideOptions,
							get = function() return db.AutoHide.OnNormal end,
							set = function(info, value)
								db.AutoHide.OnNormal = value
							end,
						},
						OnEnterCombatAutoHideSelect = {
							name = L["When entering combat"],
							desc = L["What to do when entering combat"],
							type = "select",
							order = 107,
							values = dicAutoHideOptions,
							get = function() return db.AutoHide.OnEnterCombat end,
							set = function(info, value)
								db.AutoHide.OnEnterCombat = value
							end,
						},
						OnLeaveCombatAutoHideSelect = {
							name = L["When leaving combat"],
							desc = L["What to do when leaving combat"],
							type = "select",
							order = 108,
							values = dicAutoHideOptions,
							get = function() return db.AutoHide.OnLeaveCombat end,
							set = function(info, value)
								db.AutoHide.OnLeaveCombat = value
							end,
						},
						OnEnterPetBattleAutoHideSelect = {
							name = L["When entering pet battle"],
							desc = L["What to do when entering a pet battle"],
							type = "select",
							order = 109,
							values = dicAutoHideOptions,
							get = function() return db.AutoHide.OnEnterPetBattle end,
							set = function(info, value)
								db.AutoHide.OnEnterPetBattle = value
							end,
						},
						OnLeavePetBattleAutoHideSelect = {
							name = L["When leaving pet battle"],
							desc = L["What to do when leaving a pet battle"],
							type = "select",
							order = 110,
							values = dicAutoHideOptions,
							get = function() return db.AutoHide.OnExitPetBattle end,
							set = function(info, value)
								db.AutoHide.OnExitPetBattle = value
							end,
						},
					},
				},
			},
		}
		for k,v in pairs(moduleOptions) do
			options.args[k] = (type(v) == "function") and v() or v
		end
	end
	return options	
end

local function HandleChatCommand()
	InterfaceOptionsFrame_OpenToCategory(SorhaQuestLog.optionsFrames.Profiles)
	InterfaceOptionsFrame_OpenToCategory(SorhaQuestLog.optionsFrames.SorhaQuestLog)
	InterfaceOptionsFrame:Raise()
end

function SorhaQuestLog:OnInitialize() -- Called when the addon is loaded
	self.db = LibStub("AceDB-3.0"):New("SorhaQuestLogDB", defaults, true)
	db = self.db.profile

	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
	
	self:SetupOptions()
end

function SorhaQuestLog:OnEnable() -- Called when the addon is enabled
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PET_BATTLE_OPENING_DONE")
	self:RegisterEvent("PET_BATTLE_CLOSE")
	
	-- Remove achievements from blizzard questminion to skip thier error
	SetCVar("trackerFilter", "6");
		
	-- Hook for hiding blizzard quest tracker
	self:SecureHook("WatchFrame_Update",function()
		self:HandleBlizzardTracker()
	end);

		
	-- LibDataBroker setup
	if LDB then
		SQLBroker = LDB:NewDataObject("SorhaQuestLog", {
			type = "data source",
			label = L["Quests"],
			icon = "Interface\\GossipFrame\\AvailableQuestIcon",	
			text = "0/25",
			OnClick = function(clickedframe, button)
				if button == "RightButton" then 
					if (IsAltKeyDown()) then
						db.Main.ShowAnchors = not db.Main.ShowAnchors
						SorhaQuestLog:RefreshConfig()
						
					elseif (IsControlKeyDown()) then
						LibStub("AceConfigDialog-3.0"):Open("SorhaQuestLog") 
						
					elseif (IsShiftKeyDown()) then
						for k,v in self:IterateModules() do
							if type(v.ToggleLockState) == "function" then
								v:ToggleLockState()
							end
						end
						SorhaQuestLog:RefreshConfig(false)						
					else
						LibStub("AceConfigDialog-3.0"):Open("SorhaQuestLog") 
					end
				else 
					if (IsAltKeyDown()) then
						for k,v in self:IterateModules() do
							if (k == "AchievementTracker") then
								if (self:GetModuleEnabled(k)) then
									self:SetModuleEnabled(k, false)
								else
									self:SetModuleEnabled(k, true)
								end
							end
						end				
					elseif (IsControlKeyDown()) then
						SorhaQuestLog:ToggleSorhaQuestLog() 
						
					elseif (IsShiftKeyDown()) then
						for k,v in self:IterateModules() do
							if (k == "QuestTracker") then
								if (self:GetModuleEnabled(k)) then
									self:SetModuleEnabled(k, false)
								else
									self:SetModuleEnabled(k, true)
								end
							end
						end	
						
					else
						SorhaQuestLog:ToggleSorhaQuestLog() 
					end
				end
			end,
			OnTooltipShow = function(tooltip)
				if not tooltip or not tooltip.AddLine then return end
				tooltip:AddLine(L["Sorha Quest Log"])
				tooltip:AddDoubleLine("|cffffffff" .. L["Left-click"] .. "|r", L["Show/hide All enabled minions"])
				tooltip:AddDoubleLine("|cffffffff" .. L["Shift Left-click"] .. "|r", L["Show/hide Quest minion"])
				tooltip:AddDoubleLine("|cffffffff" .. L["Alt Left-click"] .. "|r", L["Show/hide Achievement minion"])
				-- tooltip:AddDoubleLine("|cffffffff" .. L["Control Left-click"] .. "|r", L["Show/hide all enabled minions"])
				
				tooltip:AddDoubleLine("   ", "   ")
				
				tooltip:AddDoubleLine("|cffffffff" .. L["Right-click"] .. "|r", L["Show options"])
				tooltip:AddDoubleLine("|cffffffff" .. L["Shift Right-click"] .. "|r", L["Lock/unlock all minions"])
				tooltip:AddDoubleLine("|cffffffff" .. L["Alt Right-click"] .. "|r", L["Show/hide minion anchors"])
				-- tooltip:AddDoubleLine("|cffffffff" .. L["Control Right-click"] .. "|r", L["Show/hide all enabled minions"])
			end,
		})
		SorhaQuestLog.SQLBroker = SQLBroker
	end

	-- LibButtonFacade
	if (LBF) then
		LBF:RegisterSkinCallback("SorhaQuestLog", self.SkinChanged)

		local g = LBF:Group("SorhaQuestLog")
		g:Skin(db.ButtonSkins.SkinID, db.ButtonSkins.Gloss, db.ButtonSkins.Backdrop, db.ButtonSkins.Colors)
	end

	LSM.RegisterCallback(self, "LibSharedMedia_Registered", "UpdateMedia")
end

function SorhaQuestLog:GetModuleEnabled(module)
    return db.Modules[module]
end

function SorhaQuestLog:SetModuleEnabled(module, value)
	local old = db.Modules[module]
	db.Modules[module] = value
	if old ~= value then
		if value then
			self:EnableModule(module)
		else
			self:DisableModule(module)
		end
	end
end

function SorhaQuestLog:SetupOptions() --Creates options. Registers chat commands
	self.optionsFrames = {}
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("SorhaQuestLog", getOptions)
	self.optionsFrames.SorhaQuestLog = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SorhaQuestLog", nil, nil, "General")
	
	self:RegisterModuleOptions("Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db), "Profiles")
	
	LibStub("AceConsole-3.0"):RegisterChatCommand("sql", HandleChatCommand)
	LibStub("AceConsole-3.0"):RegisterChatCommand("SorhaQuestLog", HandleChatCommand)
end

function SorhaQuestLog:RegisterModuleOptions(name, optionTbl, displayName)
	moduleOptions[name] = optionTbl	
	self.optionsFrames[name] = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SorhaQuestLog", displayName or name, "SorhaQuestLog", name)
end

-- Event handlers
function SorhaQuestLog:PLAYER_ENTERING_WORLD(...)
	isInstance, instanceType = IsInInstance()

	if (isInstance == 1) then
		if (instanceType == "arena") then
			if (db.AutoHide.OnArena == "Hide") then
				SorhaQuestLog:HideSorhaQuestLog()
			elseif (db.AutoHide.OnArena == "Show") then
				SorhaQuestLog:ShowSorhaQuestLog()
			end
		elseif (instanceType == "party") then -- 5 Man
			if (db.AutoHide.OnInstance == "Hide") then
				SorhaQuestLog:HideSorhaQuestLog()
			elseif (db.AutoHide.OnInstance == "Show") then
				SorhaQuestLog:ShowSorhaQuestLog()
			end		
		elseif (instanceType == "raid") then
			if (db.AutoHide.OnRaid == "Hide") then
				SorhaQuestLog:HideSorhaQuestLog()
			elseif (db.AutoHide.OnRaid == "Show") then
				SorhaQuestLog:ShowSorhaQuestLog()
			end		
		elseif (instanceType == "pvp") then -- Battleground
			if (db.AutoHide.OnBattleground == "Hide") then
				SorhaQuestLog:HideSorhaQuestLog()
			elseif (db.AutoHide.OnBattleground == "Show") then
				SorhaQuestLog:ShowSorhaQuestLog()
			end
		end
	else
		if (db.AutoHide.OnNormal == "Hide") then
			SorhaQuestLog:HideSorhaQuestLog()
		elseif (db.AutoHide.OnNormal == "Show") then
			SorhaQuestLog:ShowSorhaQuestLog()
		end
	end
end
	
function SorhaQuestLog:PLAYER_REGEN_ENABLED(...)
	if (db.AutoHide.OnLeaveCombat == "Hide") then
		SorhaQuestLog:HideSorhaQuestLog()
	elseif (db.AutoHide.OnLeaveCombat == "Show") then
		SorhaQuestLog:ShowSorhaQuestLog()
	end
end

function SorhaQuestLog:PLAYER_REGEN_DISABLED(...)
	if (db.AutoHide.OnEnterCombat == "Hide") then
		SorhaQuestLog:HideSorhaQuestLog()
	elseif (db.AutoHide.OnEnterCombat == "Show") then
		SorhaQuestLog:ShowSorhaQuestLog()
	end
end

function SorhaQuestLog:PET_BATTLE_OPENING_DONE(...)
	if (db.AutoHide.OnEnterPetBattle == "Hide") then
		SorhaQuestLog:HideSorhaQuestLog()
	elseif (db.AutoHide.OnEnterPetBattle == "Show") then
		SorhaQuestLog:ShowSorhaQuestLog()
	end
end

function SorhaQuestLog:PET_BATTLE_CLOSE(...)
	if (db.AutoHide.OnExitPetBattle == "Hide") then
		SorhaQuestLog:HideSorhaQuestLog()
	elseif (db.AutoHide.OnExitPetBattle == "Show") then
		SorhaQuestLog:ShowSorhaQuestLog()
	end
end

function SorhaQuestLog:RefreshConfig()
	db = self.db.profile

	for k,v in self:IterateModules() do
		if self:GetModuleEnabled(k) and not v:IsEnabled() then
			self:EnableModule(k)
		elseif not self:GetModuleEnabled(k) and v:IsEnabled() then
			self:DisableModule(k)
		end
		if type(v.Refresh) == "function" then
			v:Refresh()
		end
	end

	self:HandleBlizzardTracker()
end

function SorhaQuestLog:UpdateMedia(event, mediatype, key) -- LSM getting new media
	if mediatype == "font" then
        -- if key == db.Fonts.QuestFont or key == db.Fonts.HeaderFont then 
			-- if (blnIsUpdating == false) then
				-- self:UpdateQuestMinion()
			-- end
		-- end
    end
end

function SorhaQuestLog:SkinChanged(SkinID, Gloss, Backdrop, Group, Button, Colors)
	if not(Group) then -- Addon level
		db.ButtonSkins.SkinID = SkinID
		db.ButtonSkins.Gloss = Gloss
		db.ButtonSkins.Backdrop = Backdrop
		db.ButtonSkins.Colors = Colors
	else			  -- Subgroup level
		db.ButtonSkins.SQLItemButtons.SkinID = SkinID
		db.ButtonSkins.SQLItemButtons.Gloss = Gloss
		db.ButtonSkins.SQLItemButtons.Backdrop = Backdrop
		db.ButtonSkins.SQLItemButtons.Colors = Colors	
	end
end

function SorhaQuestLog:HandleBlizzardTracker()
	if (db.Main.HideBlizzardTracker == true) then
		WatchFrame:Hide()
    else
		WatchFrame:Show()
    end
end

-- Button functions
function SorhaQuestLog:GetLogButton()
	local objButton = tremove(tblLogButtonCache)
	
	if (objButton == nil) then
		intNumberOfLogButtons = intNumberOfLogButtons + 1
		local strButtonName = strButtonPrefix .. intNumberOfLogButtons
		
		-- Create button
		objButton = self:doCreateLooseFrame("BUTTON", strButtonName, UIParent, 10, 10, 1, "LOW", 1, 1)
		objButton:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,	insets = {left = 5, right = 3, top = 3, bottom = 5}})
		objButton:SetBackdropColor(0, 0, 0, 0)
		objButton:SetBackdropBorderColor(0, 0, 0, 0)		

		-- Create buttons variables
		objButton.isHeader = nil
		objButton.isCollapsed = nil
		objButton.LogPosition = 0
		objButton.intID = 0

		-- Create Primary fontstring
		objButton.objFontString1 = objButton:CreateFontString(nil, "OVERLAY");
		objButton.objFontString1:SetFont(LSM:Fetch("font", db.Fonts.HeaderFont), 11, db.Fonts.HeaderFontOutline)
		objButton.objFontString1:SetJustifyH("LEFT")
		objButton.objFontString1:SetJustifyV("TOP")
		objButton.objFontString1:SetText("");
		objButton.objFontString1:SetShadowColor(0.0, 0.0, 0.0, 1.0)
		objButton.objFontString1:SetShadowOffset(1, -1)
		
		-- Create Secondary fontstring
		objButton.objFontString2 = objButton:CreateFontString(nil, "OVERLAY");
		objButton.objFontString2:SetFont(LSM:Fetch("font", db.Fonts.HeaderFont), 11, db.Fonts.HeaderFontOutline)
		objButton.objFontString2:SetJustifyH("LEFT")
		objButton.objFontString2:SetJustifyV("TOP")
		objButton.objFontString2:SetText("");
		objButton.objFontString2:SetShadowColor(0.0, 0.0, 0.0, 1.0)
		objButton.objFontString2:SetShadowOffset(1, -1)
	end
	
	objButton:Show()
	objButton:EnableMouse(true);
	
	return objButton
end

function SorhaQuestLog:RecycleLogButton(objButton)
	objButton:Hide()
	objButton:EnableMouse(false);
		
	objButton.objFontString1:SetText("")
	objButton.objFontString1:SetWidth(0)
	objButton.objFontString1:SetHeight(0)
	objButton.objFontString1:ClearAllPoints()
	
	objButton.objFontString2:SetText("")
	objButton.objFontString2:SetWidth(0)
	objButton.objFontString2:SetHeight(0)	
	objButton.objFontString2:ClearAllPoints()
	
	objButton:SetScript("OnEnter", nil);
	objButton:SetScript("OnLeave", nil);
	objButton:SetScript("OnClick", nil);
	
	objButton:ClearAllPoints()
	objButton.isHeader = nil
	objButton.isCollapsed = nil
	objButton.LogPosition = 0
	objButton.intID = 0
	objButton.intOffset = 0

	tinsert(tblLogButtonCache, objButton)
end

function SorhaQuestLog:GetStatusBar()
	local objStatusBar = tremove(tblStatusBarsCache)
	if (objStatusBar == nil) then
		intNumberUsedStatusBars = intNumberUsedStatusBars + 1
		objStatusBar = CreateFrame("STATUSBAR", strStatusBarPrefix .. intNumberUsedStatusBars, UIParent)
		
		objStatusBar.objFontString = objStatusBar:CreateFontString(nil, "OVERLAY");
		objStatusBar.objFontString:SetPoint("TOPLEFT", objStatusBar, "TOPLEFT", 0, -0.5);
		--objStatusBar.objFontString:SetFont(LSM:Fetch("font", db.Fonts.AchievementObjectiveFont), db.Fonts.AchievementObjectiveFontSize, db.Fonts.AchievementObjectiveFontOutline)
		objStatusBar.objFontString:SetJustifyH("CENTER")
		objStatusBar.objFontString:SetJustifyV("TOP")
		objStatusBar.objFontString:SetShadowColor(0.0, 0.0, 0.0, 1.0)
		objStatusBar.objFontString:SetShadowOffset(1, -1)
		
		objStatusBar.Background = objStatusBar:CreateTexture(nil, "BORDER")
		objStatusBar.Background:SetAllPoints(objStatusBar)
		
		objStatusBar:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground", insets = {top = -1, left = -1, bottom = -1, right = -1}})
		objStatusBar:SetBackdropColor(0, 0, 0, 1)

		objStatusBar:SetStatusBarTexture(LSM:Fetch("statusbar", "Blizzard"))
		objStatusBar.Background:SetTexture(LSM:Fetch("statusbar", "Blizzard"))
		
		objStatusBar.Background:SetVertexColor(0, 0, 0, 1)
		objStatusBar:SetStatusBarColor(0, 1, 0, 1)
	end
	return objStatusBar
end

function SorhaQuestLog:RecycleStatusBar(objStatusBar)
	objStatusBar:SetParent(UIParent)
	objStatusBar:ClearAllPoints()
	objStatusBar:Hide()

	objStatusBar:SetHeight(0)
	objStatusBar:SetWidth(0)
	
	objStatusBar.objFontString:SetText("")
	objStatusBar.objFontString:SetHeight(0)
	objStatusBar.objFontString:SetWidth(0)
	
	objStatusBar:SetMinMaxValues(0, 1);
	objStatusBar:SetValue(0);
	tinsert(tblStatusBarsCache, objStatusBar)
end

-- Utility functions
function SorhaQuestLog:RemoveObject(objTable, objFind)
	for k, v in pairs(objTable) do
		if (v == objFind) then
			tremove(objTable,k)
			break
		end
	end
end

function SorhaQuestLog:doCreateLooseFrame(strType,strName,fraParent,intWidth,intHeight,intScale,strStrata,intLevel,intAlpha,finherit) -- Returns a frame thats not anchored
	local f = CreateFrame(strType,strName,fraParent,finherit)
	f:SetWidth(intWidth)
	f:SetHeight(intHeight)
	f:SetFrameStrata(strStrata)
	f:SetFrameLevel(intLevel)	
	f:SetAlpha(intAlpha)
	return f  
end 

function SorhaQuestLog:doCreateFrame(strType,strName,fraParent,intWidth,intHeight,intScale,strStrata,intLevel,strPoint,fraRelativeFrame,strRelativePoint,intOffsetX,intOffsetY,intAlpha,finherit) -- Returns an anchored frame
	local f = CreateFrame(strType,strName,fraParent,finherit)
	
	f:SetWidth(intWidth)
	f:SetHeight(intHeight)
	f:SetFrameStrata(strStrata)
	f:SetFrameLevel(intLevel)
	f:SetPoint(strPoint,fraRelativeFrame,strRelativePoint,intOffsetX,intOffsetY)
	f:SetAlpha(intAlpha)
	return f  
end 


-- Visibility functions
function SorhaQuestLog:ShowSorhaQuestLog()
	db.Main.HideAll = false
	self:RefreshConfig()
end

function SorhaQuestLog:HideSorhaQuestLog()
	db.Main.HideAll = true
	self:RefreshConfig()
end

function SorhaQuestLog:ToggleSorhaQuestLog()
	if (db.Main.HideAll == true) then
		self:ShowSorhaQuestLog()
	else
		self:HideSorhaQuestLog()
	end
end