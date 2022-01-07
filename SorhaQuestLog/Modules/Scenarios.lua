local SorhaQuestLog = LibStub("AceAddon-3.0"):GetAddon("SorhaQuestLog")
local L = LibStub("AceLocale-3.0"):GetLocale("SorhaQuestLog")
local MODNAME = "ScenarioTracker"
local ScenarioTracker = SorhaQuestLog:NewModule(MODNAME, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0", "LibSink-2.0")

local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local LDB = LibStub:GetLibrary("LibDataBroker-1.1")

local fraMinionAnchor = nil
local blnMinionInitialized = false
local blnMinionUpdating = false

local strButtonPrefix = MODNAME .. "Button"
local intNumberUsedButtons = 0

local tblButtonCache = {}
local tblUsingButtons = {}

local strMinionTitleColour = "|cffffffff"
local strScenarioHeaderColour = "|cffffffff"
local strScenarioTaskColour = "|cffffffff"
local strScenarioObjectiveColour = "|cffffffff"

--
local intLastTimerUpdateTime = 0
local intNumTimers = 0
local tblTimers = {}
local tblMedalTimes = {}
--

local strMedal = "None"
local intTimeCurrentMedal = 0
local intTimeLeft = 0
local blnMedalNoneUpdateDone = false

local haveBonusTimer = false; 

-- ProvingGrounds --
local intPGDifficulty = 0;
local intPGCurrentWave = 0;
local intPGMaxWave = 0;
local intPGDuration = 0;
local intPGElapsedTime = 0;
local blnInProvingGround = false;


local tblMedals = {"Bronze", "Silver", "Gold"}

local dicOutlines = {
	[""] = L["None"],
	["OUTLINE"] = L["Outline"],
	["THICKOUTLINE"] = L["Thick Outline"],
}

--Defaults
local db
local dbCore
local defaults = {
	profile = {
		MinionLocation = {X = 0, Y = 0, Point = "CENTER", RelativePoint = "CENTER"},
		MinionScale = 1,
		MinionLocked = false,
		MinionWidth = 220,
		MinionCollapseToLeft = false,
		MoveTooltipsRight = false,
		ShowTitle = true,
		AutoHideTitle = false,
		StatusBarTexture = LSM.DefaultMedia.statusbar,
		Fonts = {
			-- Scenario minion title font
			MinionTitleFontSize = 11,
			MinionTitleFont = "framd",
			MinionTitleFontOutline = "",
			MinionTitleFontShadowed = true,
			
			-- Scenario header font
			ScenarioHeaderFontSize = 11,
			ScenarioHeaderFont = "framd",
			ScenarioHeaderFontOutline = "",
			ScenarioHeaderFontShadowed = true,
						
			-- Scenario task font
			ScenarioTaskFontSize = 11,
			ScenarioTaskFont = "framd",
			ScenarioTaskFontOutline = "",
			ScenarioTaskFontShadowed = true,
			
			-- Scenario objective font
			ScenarioObjectiveFontSize = 11,
			ScenarioObjectiveFont = "framd",
			ScenarioObjectiveFontOutline = "",
			ScenarioObjectiveFontShadowed = true,
		},
		Colours = {
			MinionTitleColour = {r = 0, g = 1, b = 0, a = 1},
			ScenarioHeaderColour = {r = 1, g = 1, b = 1, a = 1},
			ScenarioTaskColour = {r = 0, g = 1, b = 0, a = 1},
			ScenarioObjectiveColour = {r = 0, g = 0, b = 0, a = 1},
			StatusBarFillColour = {r = 0, g = 1, b = 0, a = 1},
			StatusBarBackColour = {r = 0, g = 0, b = 0, a = 1},
			MinionBackGroundColour = {r = 0.5, g = 0.5, b = 0.5, a = 0},
			MinionBorderColour = {r = 0.5, g = 0.5, b = 0.5, a = 0},
		}
	}
}

--Options
local options
local function getOptions()
	if not options then
		options = {
			name = L["Scenario Settings"],
			type = "group",
			childGroups = "tab",
			order = 1,
			arg = MODNAME,
			args = {
				Main = {
					name = "Main",
					type = "group",
					order = 1,
					args = {
						enabled = {
							order = 1,
							type = "toggle",
							name = L["Enable Minion"],
							get = function() return SorhaQuestLog:GetModuleEnabled(MODNAME) end,
							set = function(info, value) 
								SorhaQuestLog:SetModuleEnabled(MODNAME, value) 
								ScenarioTracker:MinionAnchorUpdate(false)
							end,
						},
						MinionLockedToggle = {
							name = L["Lock Minion"],
							type = "toggle",
							get = function() return db.MinionLocked end,
							set = function()
								db.MinionLocked = not db.MinionLocked
								ScenarioTracker:MinionAnchorUpdate(false)
							end,
							order = 2,
						},
						ShowTitleToggle = {
							name = L["Show Minion Title"],
							type = "toggle",
							width = "full",
							get = function() return db.ShowTitle end,
							set = function()
								db.ShowTitle = not db.ShowTitle
								ScenarioTracker:UpdateMinion()
							end,
							order = 3,
						},
						AutoHideTitleToggle = {
							name = L["Auto Hide Minion Title"],
							desc = L["Hide the title when there is nothing to display"],
							type = "toggle",
							width = "full",
							disabled = function() return not(db.ShowTitle) end,
							get = function() return db.AutoHideTitle end,
							set = function()
								db.AutoHideTitle = not db.AutoHideTitle
								ScenarioTracker:UpdateMinion(false)
							end,
							order = 4,
						},
						MinionSizeSlider = {
							order = 6,
							name = L["Minion Scale"],
							desc = L["Adjust the scale of the minion"],
							type = "range",
							min = 0.5, max = 2, step = 0.05,
							isPercent = false,
							get = function() return db.MinionScale end,
							set = function(info, value)
								db.MinionScale = value
								ScenarioTracker:UpdateMinion()
							end,
						},
						MinionWidth = {
							order = 7,
							name = L["Width"],
							desc = L["Adjust the width of the minion"],
							type = "range",
							min = 150, max = 600, step = 1,
							isPercent = false,
							get = function() return db.MinionWidth end,
							set = function(info, value)
								db.MinionWidth = value
								ScenarioTracker:UpdateMinion()
							end,
						},
						AchivementsSpacer = {
							name = "   ",
							width = "full",
							type = "description",
							order = 10,
						},
						AchivementsSpacerHeader = {
							name = "",
							type = "header",
							order = 11,
						},						
						StatusBarTextureSelect = {
							name = L["Bar Texture"],
							desc = L["The texture the status bars will use"],
							type = "select", dialogControl = "LSM30_Statusbar", 
							values = AceGUIWidgetLSMlists.statusbar, 
							get = function() return db.StatusBarTexture end,
							set = function(info, value)
								db.StatusBarTexture = value
								ScenarioTracker:UpdateMinion()
							end,
							order = 12,
						},
					}
				},
				Fonts = {
					name = "Fonts",
					type = "group",
					order = 5,
					args = {
						HeaderTitleFont = {
							name = L["Minion Title Font Settings"],
							type = "header",
							order = 41,
						},
						MinionTitleFontSelect = {
							type = "select", dialogControl = 'LSM30_Font',
							order = 42,
							name = L["Font"],
							desc = L["The font used for this element"],
							values = AceGUIWidgetLSMlists.font,
							get = function() return db.Fonts.MinionTitleFont end,
							set = function(info, value)
								db.Fonts.MinionTitleFont = value
								ScenarioTracker:UpdateMinion()
							end,
						},
						MinionTitleFontOutlineSelect = {
							name = L["Font Outline"],
							desc = L["The outline that this font will use"],
							type = "select",
							order = 43,
							values = dicOutlines,
							get = function() return db.Fonts.MinionTitleFontOutline end,
							set = function(info, value)
								db.Fonts.MinionTitleFontOutline = value
								ScenarioTracker:UpdateMinion()
							end,
						},
						MinionTitleFontSizeSelect = {
							order = 44,
							name = L["Font Size"],
							desc = L["Controls the font size this font"],
							type = "range",
							min = 8, max = 20, step = 1,
							isPercent = false,
							get = function() return db.Fonts.MinionTitleFontSize end,
							set = function(info, value)
								db.Fonts.MinionTitleFontSize = value
								ScenarioTracker:UpdateMinion()
							end,
						},
						MinionTitleFontShadowedToggle = {
							name = L["Shadow Text"],
							desc = L["Shows/Hides text shadowing"],
							type = "toggle",
							get = function() return db.Fonts.MinionTitleFontShadowed end,
							set = function()
								db.Fonts.MinionTitleFontShadowed = not db.Fonts.MinionTitleFontShadowed
								ScenarioTracker:UpdateMinion()
							end,
							order = 45,
						},
						HeaderFontsSpacer = {
							name = "   ",
							width = "full",
							type = "description",
							order = 50,
						},
						HeaderFonts = {
							name = L["Header Font Settings"],
							type = "header",
							order = 51,
						},
						ScenarioHeaderFontSelect = {
							type = "select", dialogControl = 'LSM30_Font',
							order = 52,
							name = L["Font"],
							desc = L["The font used for this element"],
							values = AceGUIWidgetLSMlists.font,
							get = function() return db.Fonts.ScenarioHeaderFont end,
							set = function(info, value)
								db.Fonts.ScenarioHeaderFont = value
								ScenarioTracker:UpdateMinion()
							end,
						},
						ScenarioHeaderFontOutlineSelect = {
							name = L["Font Outline"],
							desc = L["The outline that this font will use"],
							type = "select",
							order = 53,
							values = dicOutlines,
							get = function() return db.Fonts.ScenarioHeaderFontOutline end,
							set = function(info, value)
								db.Fonts.ScenarioHeaderFontOutline = value
								ScenarioTracker:UpdateMinion()
							end,
						},
						ScenarioHeaderFontSize = {
							order = 54,
							name = L["Font Size"],
							desc = L["Controls the font size this font"],
							type = "range",
							min = 8, max = 20, step = 1,
							isPercent = false,
							get = function() return db.Fonts.ScenarioHeaderFontSize end,
							set = function(info, value)
								db.Fonts.ScenarioHeaderFontSize = value
								ScenarioTracker:UpdateMinion()
							end,
						},
						ScenarioHeaderFontShadowedToggle = {
							name = L["Shadow Text"],
							desc = L["Shows/Hides text shadowing"],
							type = "toggle",
							get = function() return db.Fonts.ScenarioHeaderFontShadowed end,
							set = function()
								db.Fonts.ScenarioHeaderFontShadowed = not db.Fonts.ScenarioHeaderFontShadowed
								ScenarioTracker:UpdateMinion()
							end,
							order = 55,
						},
						TaskFontsSpacer = {
							name = "   ",
							width = "full",
							type = "description",
							order = 60,
						},
						TaskFonts = {
							name = L["Task Font Settings"],
							type = "header",
							order = 61,
						},
						ScenarioTaskFontSelect = {
							type = "select", dialogControl = 'LSM30_Font',
							order = 62,
							name = L["Font"],
							desc = L["The font used for this element"],
							values = AceGUIWidgetLSMlists.font,
							get = function() return db.Fonts.ScenarioTaskFont end,
							set = function(info, value)
								db.Fonts.ScenarioTaskFont = value
								ScenarioTracker:UpdateMinion()
							end,
						},
						ScenarioTaskFontOutlineSelect = {
							name = L["Font Outline"],
							desc = L["The outline that this font will use"],
							type = "select",
							order = 63,
							values = dicOutlines,
							get = function() return db.Fonts.ScenarioTaskFontOutline end,
							set = function(info, value)
								db.Fonts.ScenarioTaskFontOutline = value
								ScenarioTracker:UpdateMinion()
							end,
						},
						ScenarioTaskFontSize = {
							order = 64,
							name = L["Font Size"],
							desc = L["Controls the font size this font"],
							type = "range",
							min = 8, max = 20, step = 1,
							isPercent = false,
							get = function() return db.Fonts.ScenarioTaskFontSize end,
							set = function(info, value)
								db.Fonts.ScenarioTaskFontSize = value
								ScenarioTracker:UpdateMinion()
							end,
						},
						ScenarioTaskFontShadowedToggle = {
							name = L["Shadow Text"],
							desc = L["Shows/Hides text shadowing"],
							type = "toggle",
							get = function() return db.Fonts.ScenarioTaskFontShadowed end,
							set = function()
								db.Fonts.ScenarioTaskFontShadowed = not db.Fonts.ScenarioTaskFontShadowed
								ScenarioTracker:UpdateMinion()
							end,
							order = 65,
						},
						ObjectivesFontsSpacer = {
							name = "   ",
							width = "full",
							type = "description",
							order = 70,
						},
						ObjectiveFonts = {
							name = L["Objective Font Settings"],
							type = "header",
							order = 71,
						},
						ScenarioObjectiveFontSelect = {
							type = "select", dialogControl = 'LSM30_Font',
							order = 72,
							name = L["Font"],
							desc = L["The font used for this element"],
							values = AceGUIWidgetLSMlists.font,
							get = function() return db.Fonts.ScenarioObjectiveFont end,
							set = function(info, value)
								db.Fonts.ScenarioObjectiveFont = value
								ScenarioTracker:UpdateMinion()
							end,
						},
						ScenarioObjectiveFontOutlineSelect = {
							name = L["Font Outline"],
							desc = L["The outline that this font will use"],
							type = "select",
							order = 73,
							values = dicOutlines,
							get = function() return db.Fonts.ScenarioObjectiveFontOutline end,
							set = function(info, value)
								db.Fonts.ScenarioObjectiveFontOutline = value
								ScenarioTracker:UpdateMinion()
							end,
						},
						ScenarioObjectiveFontSize = {
							order = 74,
							name = L["Font Size"],
							desc = L["Controls the font size this font"],
							type = "range",
							min = 8, max = 20, step = 1,
							isPercent = false,
							get = function() return db.Fonts.ScenarioObjectiveFontSize end,
							set = function(info, value)
								db.Fonts.ScenarioObjectiveFontSize = value
								ScenarioTracker:UpdateMinion()
							end,
						},
						ScenarioObjectiveFontShadowedToggle = {
							name = L["Shadow Text"],
							desc = L["Shows/Hides text shadowing"],
							type = "toggle",
							get = function() return db.Fonts.ScenarioObjectiveFontShadowed end,
							set = function()
								db.Fonts.ScenarioObjectiveFontShadowed = not db.Fonts.ScenarioObjectiveFontShadowed
								ScenarioTracker:UpdateMinion()
							end,
							order = 75,
						},				
					}
				},
				Colours = {
					name = "Colours",
					type = "group",
					order = 6,
					args = {
						HeaderColourSettings = {
							name = L["Colour Settings"],
							type = "header",
							order = 80,
						},
						MinionTitleColour = {
							name = L["Minion Title"],
							desc = L["Sets the color for Minion Title"],
							type = "color",
							width = "full",
							hasAlpha = true,
							get = function() return db.Colours.MinionTitleColour.r, db.Colours.MinionTitleColour.g, db.Colours.MinionTitleColour.b, db.Colours.MinionTitleColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.MinionTitleColour.r = r
									db.Colours.MinionTitleColour.g = g
									db.Colours.MinionTitleColour.b = b
									db.Colours.MinionTitleColour.a = a
									ScenarioTracker:HandleColourChanges()
								end,
							order = 81,
						},
						ScenarioHeaderColour = {
							name = L["Scenario Headers"],
							desc = L["Sets the color for Scenario Headers"],
							type = "color",
							hasAlpha = true,
							get = function() return db.Colours.ScenarioHeaderColour.r, db.Colours.ScenarioHeaderColour.g, db.Colours.ScenarioHeaderColour.b, db.Colours.ScenarioHeaderColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.ScenarioHeaderColour.r = r
									db.Colours.ScenarioHeaderColour.g = g
									db.Colours.ScenarioHeaderColour.b = b
									db.Colours.ScenarioHeaderColour.a = a
									ScenarioTracker:HandleColourChanges()
								end,
							order = 82,
						},
						ScenarioTaskColour = {
							name = L["Scenario Tasks"],
							desc = L["Sets the color for Scenario Tasks"],
							type = "color",
							hasAlpha = true,
							get = function() return db.Colours.ScenarioTaskColour.r, db.Colours.ScenarioTaskColour.g, db.Colours.ScenarioTaskColour.b, db.Colours.ScenarioTaskColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.ScenarioTaskColour.r = r
									db.Colours.ScenarioTaskColour.g = g
									db.Colours.ScenarioTaskColour.b = b
									db.Colours.ScenarioTaskColour.a = a
									ScenarioTracker:HandleColourChanges()
								end,
							order = 83,
						},
						ScenarioObjectiveColour = {
							name = L["Scenario Objectives"],
							desc = L["Sets the color for Scenario Objectives"],
							type = "color",
							hasAlpha = true,
							get = function() return db.Colours.ScenarioObjectiveColour.r, db.Colours.ScenarioObjectiveColour.g, db.Colours.ScenarioObjectiveColour.b, db.Colours.ScenarioObjectiveColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.ScenarioObjectiveColour.r = r
									db.Colours.ScenarioObjectiveColour.g = g
									db.Colours.ScenarioObjectiveColour.b = b
									db.Colours.ScenarioObjectiveColour.a = a
									ScenarioTracker:HandleColourChanges()
								end,
							order = 84,
						},
						StatusBarFillColour = {
							name = L["Bar Fill Colour"],
							desc = L["Sets the color for the completed part of the status bar"],
							type = "color",
							hasAlpha = true,
							get = function() return db.Colours.StatusBarFillColour.r, db.Colours.StatusBarFillColour.g, db.Colours.StatusBarFillColour.b, db.Colours.StatusBarFillColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.StatusBarFillColour.r = r
									db.Colours.StatusBarFillColour.g = g
									db.Colours.StatusBarFillColour.b = b
									db.Colours.StatusBarFillColour.a = a
									ScenarioTracker:UpdateMinion()
								end,
							order = 85,
						},
						StatusBarBackColour = {
							name = L["Bar Back Colour"],
							desc = L["Sets the color for the un-completed part of the status bar"],
							type = "color",
							hasAlpha = true,
							get = function() return db.Colours.StatusBarBackColour.r, db.Colours.StatusBarBackColour.g, db.Colours.StatusBarBackColour.b, db.Colours.StatusBarBackColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.StatusBarBackColour.r = r
									db.Colours.StatusBarBackColour.g = g
									db.Colours.StatusBarBackColour.b = b
									db.Colours.StatusBarBackColour.a = a
									ScenarioTracker:UpdateMinion()
								end,
							order = 86,
						},
						MinionBackGroundColour = {
							name = L["Background Colour"],
							desc = L["Sets the color of the minions background"],
							type = "color",
							hasAlpha = true,
							get = function() return db.Colours.MinionBackGroundColour.r, db.Colours.MinionBackGroundColour.g, db.Colours.MinionBackGroundColour.b, db.Colours.MinionBackGroundColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.MinionBackGroundColour.r = r
									db.Colours.MinionBackGroundColour.g = g
									db.Colours.MinionBackGroundColour.b = b
									db.Colours.MinionBackGroundColour.a = a
									ScenarioTracker:HandleColourChanges()
								end,
							order = 87,
						},
						MinionBorderColour = {
							name = L["Border Colour"],
							desc = L["Sets the color of the minions border"],
							type = "color",
							hasAlpha = true,
							get = function() return db.Colours.MinionBorderColour.r, db.Colours.MinionBorderColour.g, db.Colours.MinionBorderColour.b, db.Colours.MinionBorderColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.MinionBorderColour.r = r
									db.Colours.MinionBorderColour.g = g
									db.Colours.MinionBorderColour.b = b
									db.Colours.MinionBorderColour.a = a
									ScenarioTracker:HandleColourChanges()
								end,
							order = 88,
						},
					}
				},
			}
		}
	end


	return options
end

--Inits
function ScenarioTracker:OnInitialize()
	self.db = SorhaQuestLog.db:RegisterNamespace(MODNAME, defaults)
	db = self.db.profile
	dbCore = SorhaQuestLog.db.profile
	self:SetEnabledState(SorhaQuestLog:GetModuleEnabled(MODNAME))
	SorhaQuestLog:RegisterModuleOptions(MODNAME, getOptions, L["Scenario Tracker"])
	
	self:UpdateColourStrings()
	self:MinionAnchorUpdate(true)
end

function ScenarioTracker:OnEnable()
	self:RegisterEvent("QUEST_LOG_UPDATE")	
	self:RegisterEvent("PLAYER_ENTERING_WORLD")	
	
	self:RegisterEvent("SCENARIO_UPDATE")
	self:RegisterEvent("SCENARIO_CRITERIA_UPDATE")
	
	self:RegisterEvent("WORLD_STATE_TIMER_START")
	self:RegisterEvent("WORLD_STATE_TIMER_STOP")
	
	
	self:MinionAnchorUpdate(false)
	self:UpdateMinion()
end

function ScenarioTracker:OnDisable()
	self:UnregisterEvent("QUEST_LOG_UPDATE")		
	self:UnregisterEvent("SCENARIO_UPDATE")
	self:UnregisterEvent("SCENARIO_CRITERIA_UPDATE")	
	self:UnregisterEvent("WORLD_STATE_TIMER_START")
	self:UnregisterEvent("WORLD_STATE_TIMER_STOP")
	self:UpdateMinion()
end

function ScenarioTracker:Refresh()
	db = self.db.profile
	dbCore = SorhaQuestLog.db.profile
	
	self:HandleColourChanges()
	self:MinionAnchorUpdate(true)
end

--Events/handlers
function ScenarioTracker:QUEST_LOG_UPDATE(...)
	if (blnMinionUpdating == false) then 
		blnMinionUpdating = true
		self:ScheduleTimer("UpdateMinion", 0.3)
	end
end

function ScenarioTracker:SCENARIO_UPDATE(...)
	if (blnMinionUpdating == false) then 
		self:UpdateMinion();
	end
end

function ScenarioTracker:SCENARIO_CRITERIA_UPDATE(...)
	if (blnMinionUpdating == false) then 
		self:UpdateMinion();
	end
end

function ScenarioTracker:PLAYER_ENTERING_WORLD(self,event, ...)

end

function ScenarioTracker:WORLD_STATE_TIMER_START(self,event, ...)
	local difficulty, curWave, maxWave, duration = C_Scenario.GetProvingGroundsInfo();

	local provingGroundSum = difficulty + curWave + maxWave + duration;
	if (provingGroundSum > 0) then
		intPGDifficulty = difficulty;
		intPGCurrentWave = curWave;
		intPGMaxWave = maxWave;
		intPGDuration = duration;
		intPGElapsedTime = 0;
		blnInProvingGround = true;
	end
end

function ScenarioTracker:WORLD_STATE_TIMER_STOP(self,event, ...)
	blnInProvingGround = false;
end

--Buttons
function ScenarioTracker:GetMinionButton()
	return SorhaQuestLog:GetLogButton();
end

function ScenarioTracker:RecycleMinionButton(objButton)
	if (objButton.StatusBar ~= nil) then
		self:RecycleStatusBar(objButton.StatusBar)
		objButton.StatusBar = nil
	end
	SorhaQuestLog:RecycleLogButton(objButton)
end

function ScenarioTracker:GetStatusBar()
	return SorhaQuestLog:GetStatusBar()
end

function ScenarioTracker:RecycleStatusBar(objStatusBar)
	SorhaQuestLog:RecycleStatusBar(objStatusBar)
end

--Minion
function ScenarioTracker:CreateMinionLayout()
	fraMinionAnchor = SorhaQuestLog:doCreateFrame("FRAME","SQLScenarioQuestsMinionAnchor",UIParent,200,20,1,"BACKGROUND",1, db.MinionLocation.Point, UIParent, db.MinionLocation.RelativePoint, db.MinionLocation.X, db.MinionLocation.Y, 1)
	fraMinionAnchor:SetMovable(true)
	fraMinionAnchor:SetClampedToScreen(true)
	fraMinionAnchor:RegisterForDrag("LeftButton")
	fraMinionAnchor:SetScript("OnUpdate", self.UpdateMinionOnTimer)
	fraMinionAnchor:SetScript("OnDragStart", fraMinionAnchor.StartMoving)
	fraMinionAnchor:SetScript("OnDragStop",  function(self)
		fraMinionAnchor:StopMovingOrSizing()
		local strPoint, tempB, strRelativePoint, intPosX, intPosY = fraMinionAnchor:GetPoint()
		db.MinionLocation.Point = strPoint
		db.MinionLocation.RelativePoint = strRelativePoint
		db.MinionLocation.X = intPosX
		db.MinionLocation.Y = intPosY
	end)
	fraMinionAnchor:SetScript("OnEnter", function(self) 
		if (dbCore.Main.ShowHelpTooltips == true) then
			if (db.MoveItemsAndTooltipsRight == true) then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0);
			else 
				GameTooltip:SetOwner(self, "ANCHOR_LEFT", 0, 0);
			end
			
			GameTooltip:SetText(L["Scenario Quests Minion Anchor"], 0, 1, 0, 1);
			GameTooltip:AddLine(L["Drag this to move the Scenario Quests minion when it is unlocked.\n"], 1, 1, 1, 1);
			GameTooltip:AddLine(L["You can disable help tooltips in general settings"], 0.5, 0.5, 0.5, 1);
			
			GameTooltip:Show();
		end
	end)
	fraMinionAnchor:SetScript("OnLeave", function(self) 
		GameTooltip:Hide()
	end)
	
	fraMinionAnchor:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,	insets = {left = 5, right = 3, top = 3, bottom = 5}})
	fraMinionAnchor:SetBackdropColor(0, 0, 0, 0)
	fraMinionAnchor:SetBackdropBorderColor(0, 0, 0, 0)

	-- scenario Anchor
	fraMinionAnchor.fraScenariosAnchor = SorhaQuestLog:doCreateLooseFrame("FRAME","SQLSenarioQuestsAnchor",fraMinionAnchor, fraMinionAnchor:GetWidth(),1,1,"LOW",1,1)
	fraMinionAnchor.fraScenariosAnchor:SetPoint("TOPLEFT", fraMinionAnchor, "TOPLEFT", 0, 0);
	fraMinionAnchor.fraScenariosAnchor:SetBackdropColor(0, 0, 0, 0)
	fraMinionAnchor.fraScenariosAnchor:SetBackdropBorderColor(0,0,0,0)
	fraMinionAnchor.fraScenariosAnchor:SetAlpha(0)
	
	-- Fontstring for title "Remote Quests"
	fraMinionAnchor.objFontString = fraMinionAnchor:CreateFontString(nil, "OVERLAY");
	fraMinionAnchor.objFontString:SetPoint("TOPLEFT", fraMinionAnchor, "TOPLEFT",0, 0);
	fraMinionAnchor.objFontString:SetFont(LSM:Fetch("font", db.Fonts.MinionTitleFont), db.Fonts.MinionTitleFontSize , db.Fonts.MinionTitleFontOutline)
	if (db.Fonts.MinionTitleFontShadowed == true) then
		fraMinionAnchor.objFontString:SetShadowColor(0.0, 0.0, 0.0, 1.0)
	else
		fraMinionAnchor.objFontString:SetShadowColor(0.0, 0.0, 0.0, 0.0)
	end
	
	fraMinionAnchor.objFontString:SetJustifyH("LEFT")
	fraMinionAnchor.objFontString:SetJustifyV("TOP")
	fraMinionAnchor.objFontString:SetText("");
	fraMinionAnchor.objFontString:SetShadowOffset(1, -1)
	
	fraMinionAnchor.BorderFrame = SorhaQuestLog:doCreateFrame("FRAME","SQLScenarioQuestsMinionBorder", fraMinionAnchor, 100,20,1,"BACKGROUND",1, "TOPLEFT", fraMinionAnchor, "TOPLEFT", -6, 6, 1)
	fraMinionAnchor.BorderFrame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,	insets = {left = 5, right = 3, top = 3, bottom = 5}})
	fraMinionAnchor.BorderFrame:SetBackdropColor(db.Colours.MinionBackGroundColour.r, db.Colours.MinionBackGroundColour.g, db.Colours.MinionBackGroundColour.b, db.Colours.MinionBackGroundColour.a)
	fraMinionAnchor.BorderFrame:SetBackdropBorderColor(db.Colours.MinionBorderColour.r, db.Colours.MinionBorderColour.g, db.Colours.MinionBorderColour.b, db.Colours.MinionBorderColour.a)
	fraMinionAnchor.BorderFrame:Show()
	
	blnMinionInitialized = true
	self:MinionAnchorUpdate(false)
end

function ScenarioTracker:UpdateMinion()
	blnMinionUpdating = true
	haveBonusTimer = false;
	
	-- If Scenario Minion is not Initialized then do so
	if (blnMinionInitialized == false) then
		self:CreateMinionLayout()
	end
	if (self:IsVisible() == false) then
		blnMinionUpdating = false
		return ""
	end
	
	-- Release all used buttons
	for k, objButton in pairs(tblUsingButtons) do
		self:RecycleMinionButton(objButton)
	end
	wipe(tblUsingButtons)
	
	local intYPosition = 4	
	local intLargestWidth = 0
	local blnNothingShown = true
	
	local inScenario = C_Scenario.IsInScenario();
	local inChallengeMode = C_Scenario.IsChallengeMode();
	-- Show title if enabled
	if (db.ShowTitle == true and (db.AutoHideTitle == false or (db.AutoHideTitle == true and (inScenario == true or inChallengeMode == true or blnInProvingGround == true)))) then
		fraMinionAnchor.objFontString:SetFont(LSM:Fetch("font", db.Fonts.MinionTitleFont), db.Fonts.MinionTitleFontSize, db.Fonts.MinionTitleFontOutline)
		if (db.Fonts.MinionTitleFontShadowed == true) then
			fraMinionAnchor.objFontString:SetShadowColor(0.0, 0.0, 0.0, 1.0)
		else
			fraMinionAnchor.objFontString:SetShadowColor(0.0, 0.0, 0.0, 0.0)
		end
		
		fraMinionAnchor.objFontString:SetText(strMinionTitleColour .. L["Scenario Tracker Title"])
		intLargestWidth = fraMinionAnchor.objFontString:GetWidth()
		
		intYPosition = db.Fonts.MinionTitleFontSize
		blnNothingShown = false
	else
		fraMinionAnchor.objFontString:SetText("")
		intLargestWidth = 100
	end			
	fraMinionAnchor:SetWidth(db.MinionWidth)	
	
	
	--Get outlining offsets
	local intTitleOutlineOffset = 0
	local intHeaderOutlineOffset = 0
	local intTaskOutlineOffset = 0
	local intObjectiveOutlineOffset = 0
	if (db.Fonts.MinionTitleFontOutline == "THICKOUTLINE") then
		intTitleOutlineOffset = 2
	elseif (db.Fonts.MinionTitleFontOutline == "OUTLINE") then
		intTitleOutlineOffset = 1
	end
	if (db.Fonts.ScenarioHeaderFontOutline == "THICKOUTLINE") then
		intHeaderOutlineOffset = 1.5
	elseif (db.Fonts.ScenarioHeaderFontOutline == "OUTLINE") then
		intHeaderOutlineOffset = 0.5
	end
	if (db.Fonts.ScenarioTaskFontOutline == "THICKOUTLINE") then
		intTaskOutlineOffset = 1.5
	elseif (db.Fonts.ScenarioTaskFontOutline == "OUTLINE") then
		intTaskOutlineOffset = 0.5
	end
	if (db.Fonts.ScenarioObjectiveFontOutline == "THICKOUTLINE") then
		intObjectiveOutlineOffset = 1.5
	elseif (db.Fonts.ScenarioObjectiveFontOutline == "OUTLINE") then
		intObjectiveOutlineOffset = 0.5
	end
	
	local intInitialYOffset = intYPosition
	blnMedalNoneUpdateDone = true
	if ((inScenario and blnInProvingGround == false) or inChallengeMode) then
		blnNothingShown = false;
		--Get scenario info
		local name, currentStage, numStages, flags, hasBonusStep, isBonusStepComplete = C_Scenario.GetInfo();
		
		if ( currentStage > 0 and (currentStage <= numStages or hasBonusStep)) then		
			local stageName, stageDescription, numCriteria = C_Scenario.GetStepInfo();			
			local intOffset = 0
			
			local inChallengeMode = C_Scenario.IsChallengeMode();			
			local strTitle = ""
			local strTaskOrTimer = ""
			
			--Setup Strings
			if (inChallengeMode == true) then							
				strTaskOrTimer = ""
				if (strMedal == "None") then
					strTitle = strScenarioHeaderColour .. stageName .. ": No Medal|r"	
				else
					strTitle = strScenarioHeaderColour ..  stageName .. ": " .. strMedal .."|r"	
				end
			else
				strTitle = strScenarioHeaderColour .. "Stage: " .. currentStage .. "/" .. numStages  .. "|r"
				strTaskOrTimer= strScenarioTaskColour .. stageName .. "|r"		
			end
		
			local objButton = self:GetMinionButton();
			objButton:SetScale(db.MinionScale)
			objButton:SetWidth(db.MinionWidth)
			objButton:SetParent(fraMinionAnchor);
			objButton:SetPoint("TOPLEFT", fraMinionAnchor.fraScenariosAnchor, "TOPLEFT", 0, -intYPosition);
			local objButtonHeight = 0

			objButton:SetScript("OnEnter", function(self) 
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0);			
				GameTooltip:SetText(stageName, 0, 1, 0, 1);
				GameTooltip:AddLine(stageDescription, 1, 1, 1, 1);
				GameTooltip:Show();
			end)
			objButton:SetScript("OnLeave", function(self) 
				GameTooltip:Hide()
			end)
			
			
			--Chall/Scen Title Header
			objButton.objFontString1:SetPoint("TOPLEFT", objButton, "TOPLEFT", 0, 0);
			objButton.objFontString1:SetFont(LSM:Fetch("font", db.Fonts.ScenarioHeaderFont), db.Fonts.ScenarioHeaderFontSize, db.Fonts.ScenarioHeaderFontOutline)
			if (db.Fonts.ScenarioHeaderFontShadowed == true) then
				objButton.objFontString1:SetShadowColor(0.0, 0.0, 0.0, 1.0)
			else
				objButton.objFontString1:SetShadowColor(0.0, 0.0, 0.0, 0.0)
			end		

			objButton.objFontString1:SetText(strTitle);
			objButton.objFontString1:SetWidth(db.MinionWidth)
			
			intOffset = objButton.objFontString1:GetHeight() + intHeaderOutlineOffset
			if (objButton.objFontString1:GetWidth() > intLargestWidth) then
				intLargestWidth = objButton.objFontString1:GetWidth()
			end
			intYPosition = intYPosition + intOffset	
			objButtonHeight = objButtonHeight + intOffset;
			
			--Scenario Task//Challenge timer	
			if (currentStage <= numStages) then			
				if (inChallengeMode ~= true) then
					objButton.objFontString2:SetPoint("TOPLEFT", objButton, "TOPLEFT", 0, -intOffset);
					objButton.objFontString2:SetFont(LSM:Fetch("font", db.Fonts.ScenarioTaskFont), db.Fonts.ScenarioTaskFontSize, db.Fonts.ScenarioTaskFontOutline)
					if (db.Fonts.ScenarioTaskFontShadowed == true) then
						objButton.objFontString2:SetShadowColor(0.0, 0.0, 0.0, 1.0)
					else
						objButton.objFontString2:SetShadowColor(0.0, 0.0, 0.0, 0.0)
					end
					
					objButton.objFontString2:SetText(strTaskOrTimer);					
					objButton.objFontString2:SetWidth(db.MinionWidth)

					intOffset = objButton.objFontString2:GetHeight() + intTaskOutlineOffset			
					if (objButton.objFontString2:GetWidth() > intLargestWidth) then
						intLargestWidth = objButton.objFontString2:GetWidth()
					end
					intYPosition = intYPosition + intOffset	
					objButtonHeight = objButtonHeight + intOffset;			
				else
					if (strMedal ~= "None") then
						local intStatusBarOffset = 2
						intOffset = intOffset + intStatusBarOffset
						if (objButton.StatusBar == nil) then
							objButton.StatusBar = ScenarioTracker:GetStatusBar()
						end
					
						objButton.StatusBar:Show()
						objButton.StatusBar:SetParent(objButton)
						objButton.StatusBar:SetPoint("TOPLEFT", objButton, "TOPLEFT", 0, -intOffset);
						
						-- Setup colours and texture
						objButton.StatusBar:SetStatusBarTexture(LSM:Fetch("statusbar", db.StatusBarTexture))
						objButton.StatusBar:SetStatusBarColor(db.Colours.StatusBarFillColour.r, db.Colours.StatusBarFillColour.g, db.Colours.StatusBarFillColour.b, db.Colours.StatusBarFillColour.a)
						
						objButton.StatusBar.Background:SetTexture(LSM:Fetch("statusbar", db.StatusBarTexture))			
						objButton.StatusBar.Background:SetVertexColor(db.Colours.StatusBarBackColour.r, db.Colours.StatusBarBackColour.g, db.Colours.StatusBarBackColour.b, db.Colours.StatusBarBackColour.a)
						
						objButton.StatusBar:SetBackdropColor(db.Colours.StatusBarBackColour.r, db.Colours.StatusBarBackColour.g, db.Colours.StatusBarBackColour.b, db.Colours.StatusBarBackColour.a)

						
						objButton.StatusBar.objFontString:SetFont(LSM:Fetch("font", db.Fonts.ScenarioTaskFont), db.Fonts.ScenarioTaskFontSize, db.Fonts.ScenarioHeaderFontOutline)
						if (db.Fonts.ScenarioTaskFontShadowed == true) then
							objButton.StatusBar.objFontString:SetShadowColor(0.0, 0.0, 0.0, 1.0)
						else
							objButton.StatusBar.objFontString:SetShadowColor(0.0, 0.0, 0.0, 0.0)
						end
						
						objButton.StatusBar.objFontString:SetText(self:SecondsToFormatedTime(intTimeLeft))
						
						-- Find out if string is larger then the current largest string
						if (objButton.StatusBar.objFontString:GetWidth() > intLargestWidth) then
							intLargestWidth = objButton.StatusBar.objFontString:GetWidth()
						end
						objButton.StatusBar.objFontString:SetWidth(db.MinionWidth)
						objButton.StatusBar:SetWidth(db.MinionWidth)
						objButton.StatusBar:SetHeight(objButton.StatusBar.objFontString:GetHeight() + 1)	

						
						objButton.StatusBar:SetMinMaxValues(0, intTimeCurrentMedal);
						objButton.StatusBar:SetValue(intTimeLeft);
						
						intOffset = objButton.StatusBar:GetHeight() + intStatusBarOffset			
						if (objButton.StatusBar:GetWidth() > intLargestWidth) then
							intLargestWidth = objButton.StatusBar:GetWidth()
						end
						intYPosition = intYPosition + intOffset	
						objButtonHeight = objButtonHeight + intOffset;					
					end
				end		
			end
			objButton:SetHeight(objButtonHeight)				
			tinsert(tblUsingButtons,objButton)	
				
			--Objectives
			for i = 1, numCriteria do
				local criteriaString, criteriaType, criteriaCompleted, quantity, totalQuantity, flags, assetID, quantityString, criteriaID = C_Scenario.GetCriteriaInfo(i);	
							
				local objCriteriaButton = self:GetMinionButton();
				objCriteriaButton:SetScale(db.MinionScale)
				objCriteriaButton:SetWidth(db.MinionWidth)				
				objCriteriaButton:SetParent(objButton);
				objCriteriaButton:SetPoint("TOPLEFT", fraMinionAnchor.fraScenariosAnchor, "TOPLEFT", 0, -intYPosition);
				local buttonHeight = 0
				
				criteriaString = string.format("%s: %d/%d", criteriaString, quantity, totalQuantity);

				--Objective
				objCriteriaButton.objFontString1:SetPoint("TOPLEFT", objCriteriaButton, "TOPLEFT", 0, 0);
				objCriteriaButton.objFontString1:SetFont(LSM:Fetch("font", db.Fonts.ScenarioObjectiveFont), db.Fonts.ScenarioObjectiveFontSize, db.Fonts.ScenarioObjectiveFontOutline)
				if (db.Fonts.ScenarioObjectiveFontShadowed == true) then
					objCriteriaButton.objFontString1:SetShadowColor(0.0, 0.0, 0.0, 1.0)
				else
					objCriteriaButton.objFontString1:SetShadowColor(0.0, 0.0, 0.0, 0.0)
				end
				objCriteriaButton.objFontString1:SetText(strScenarioObjectiveColour .. criteriaString .. "|r");
				objCriteriaButton.objFontString1:SetWidth(db.MinionWidth)
				
				intOffset = objCriteriaButton.objFontString1:GetHeight() + intTitleOutlineOffset + intHeaderOutlineOffset + intTaskOutlineOffset + intObjectiveOutlineOffset
				if (objCriteriaButton.objFontString1:GetWidth() > intLargestWidth) then
					intLargestWidth = objCriteriaButton.objFontString1:GetWidth()
				end
				intYPosition = intYPosition + intOffset	
				buttonHeight = buttonHeight + intOffset
				
				objCriteriaButton:SetHeight(buttonHeight)					
				tinsert(tblUsingButtons,objCriteriaButton)	
			end
			
			if (hasBonusStep) then 
				local bonusName, bonusDescription, numBonusCriteria, bonusStepFailed = C_Scenario.GetBonusStepInfo();

				local bonusCriteriaString = strScenarioTaskColour .. bonusName .. "|r"
				if (bonusStepFailed) then 
					bonusCriteriaString = bonusCriteriaString .. "|cffff2222 (FAILED)|r";
				end
				bonusCriteriaString = bonusCriteriaString .. "\n";
				
				for i = 1, numBonusCriteria do
					local criteriaString, criteriaType, criteriaCompleted, quantity, totalQuantity, flags, assetID, quantityString, criteriaID, timeLeft, criteriaFailed = C_Scenario.GetBonusCriteriaInfo(i);
					
					-- there should only be 1 timer event...
					if ( timeLeft and timeLeft > 0 and not criteriaCompleted and not criteriaFailed ) then
						haveBonusTimer = true;
						bonusCriteriaString = bonusCriteriaString .. "Time Left: " .. GetTimeStringFromSeconds(timeLeft, nil, true) .. "\n";		
					end
					
					criteriaString = string.format("%d/%d %s", quantity, totalQuantity, criteriaString);					
					if (criteriaFailed) then
						criteriaString = criteriaString .. " (Failed)"
					end
					
					bonusCriteriaString = bonusCriteriaString .. strScenarioObjectiveColour .. " - " .. criteriaString .. "|r\n"
				end		
				
				
				intYPosition = intYPosition + 10;
				
				local objBonusButton = self:GetMinionButton();
				objBonusButton:SetScale(db.MinionScale)
				objBonusButton:SetWidth(db.MinionWidth)				
				objBonusButton:SetParent(objButton);
				objBonusButton:SetPoint("TOPLEFT", fraMinionAnchor.fraScenariosAnchor, "TOPLEFT", 0, -intYPosition);
				local buttonHeight = 0					

				
				-- TOOLTIP
				objBonusButton:SetScript("OnEnter", function(self) 
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0);			
					GameTooltip:SetText(bonusName, 0, 1, 0, 1);
					GameTooltip:AddLine(bonusDescription, 1, 1, 1, 1);
					GameTooltip:AddLine(" ");
					GameTooltip:AddLine(bonusCriteriaString, 1, 1, 1, 1);
					
					-- REWARDS
					local dungeonID, randomID = GetPartyLFGID();
					if ( randomID ) then
						-- random takes precedence for determing rewards
						dungeonID = randomID;
					end
					if ( dungeonID ) then
						local firstReward = true;
						local numRewards = select(6, GetLFGDungeonRewards(dungeonID));
						for i = 1, numRewards do
							local name, texturePath, quantity, isBonusCurrency = GetLFGDungeonRewardInfo(dungeonID, i);
							if ( isBonusCurrency ) then
								if ( firstReward ) then
									GameTooltip:AddLine(" ");
									GameTooltip:AddLine(SCENARIO_BONUS_REWARD, 1, 0.831, 0.380);
									firstReward = false;
								end
								GameTooltip:AddLine(format(SCENARIO_BONUS_CURRENCY_FORMAT, quantity, name), 1, 1, 1);
								GameTooltip:AddTexture(texturePath);
							end
						end
					end
					
					GameTooltip:Show();
				end)
				objBonusButton:SetScript("OnLeave", function(self) 
					GameTooltip:Hide()
				end)
				

				--Bonus Critera
				objBonusButton.objFontString1:SetPoint("TOPLEFT", objBonusButton, "TOPLEFT", 0, 0);
				objBonusButton.objFontString1:SetFont(LSM:Fetch("font", db.Fonts.ScenarioObjectiveFont), db.Fonts.ScenarioObjectiveFontSize, db.Fonts.ScenarioObjectiveFontOutline)
				if (db.Fonts.ScenarioObjectiveFontShadowed == true) then
					objBonusButton.objFontString1:SetShadowColor(0.0, 0.0, 0.0, 1.0)
				else
					objBonusButton.objFontString1:SetShadowColor(0.0, 0.0, 0.0, 0.0)
				end
				
				objBonusButton.objFontString1:SetText(strScenarioObjectiveColour .. bonusCriteriaString .. "|r");
				objBonusButton.objFontString1:SetWidth(db.MinionWidth)
				
				intOffset = objBonusButton.objFontString1:GetHeight() + intTitleOutlineOffset + intHeaderOutlineOffset + intTaskOutlineOffset + intObjectiveOutlineOffset
				if (objBonusButton.objFontString1:GetWidth() > intLargestWidth) then
					intLargestWidth = objBonusButton.objFontString1:GetWidth()
				end
				intYPosition = intYPosition + intOffset	
				buttonHeight = buttonHeight + intOffset
				
				objBonusButton:SetHeight(buttonHeight)					
				tinsert(tblUsingButtons,objBonusButton)				
			end
		end	
	elseif (blnInProvingGround == true) then
			-- local intPGDifficulty = 0;
			-- local intPGCurrentWave = 0;
			-- local intPGMaxWave = 0;
			-- local intPGDuration = 0;
			-- local intPGElapsedTime = 0;
			-- local blnInProvingGround = false;
	
		blnNothingShown = false;
		local intOffset = 0
		
		local strLevel = "Bronze";
		if (intPGDifficulty == 2) then
			strLevel = "Silver";
		elseif (intPGDifficulty == 3) then
			strLevel = "Gold";
		elseif (intPGDifficulty == 4) then
			strLevel = "Endless";
		end
		
		local strTitle = strScenarioHeaderColour .. strLevel .. " - Wave: " .. intPGCurrentWave .. "/" .. intPGMaxWave  .. "|r"
		
		local intTimeLeft = intPGDuration - intPGElapsedTime;
		
		local objButton = self:GetMinionButton();
		objButton:SetScale(db.MinionScale)
		objButton:SetWidth(db.MinionWidth)
		objButton:SetParent(fraMinionAnchor);
		objButton:SetPoint("TOPLEFT", fraMinionAnchor.fraScenariosAnchor, "TOPLEFT", 0, -intYPosition);
		local objButtonHeight = 0
		
		--Title
		objButton.objFontString1:SetPoint("TOPLEFT", objButton, "TOPLEFT", 0, 0);
		objButton.objFontString1:SetFont(LSM:Fetch("font", db.Fonts.ScenarioHeaderFont), db.Fonts.ScenarioHeaderFontSize, db.Fonts.ScenarioHeaderFontOutline)
		if (db.Fonts.ScenarioHeaderFontShadowed == true) then
			objButton.objFontString1:SetShadowColor(0.0, 0.0, 0.0, 1.0)
		else
			objButton.objFontString1:SetShadowColor(0.0, 0.0, 0.0, 0.0)
		end		

		objButton.objFontString1:SetText(strTitle);
		objButton.objFontString1:SetWidth(db.MinionWidth)
		
		intOffset = objButton.objFontString1:GetHeight() + intHeaderOutlineOffset
		if (objButton.objFontString1:GetWidth() > intLargestWidth) then
			intLargestWidth = objButton.objFontString1:GetWidth()
		end
		intYPosition = intYPosition + intOffset	
		objButtonHeight = objButtonHeight + intOffset;
	
		--Timer		
		local intStatusBarOffset = 2
		intOffset = intOffset + intStatusBarOffset
		if (objButton.StatusBar == nil) then
			objButton.StatusBar = ScenarioTracker:GetStatusBar()
		end
	
		objButton.StatusBar:Show()
		objButton.StatusBar:SetParent(objButton)
		objButton.StatusBar:SetPoint("TOPLEFT", objButton, "TOPLEFT", 0, -intOffset);
		
		-- Setup colours and texture
		objButton.StatusBar:SetStatusBarTexture(LSM:Fetch("statusbar", db.StatusBarTexture))
		objButton.StatusBar:SetStatusBarColor(db.Colours.StatusBarFillColour.r, db.Colours.StatusBarFillColour.g, db.Colours.StatusBarFillColour.b, db.Colours.StatusBarFillColour.a)
		
		objButton.StatusBar.Background:SetTexture(LSM:Fetch("statusbar", db.StatusBarTexture))			
		objButton.StatusBar.Background:SetVertexColor(db.Colours.StatusBarBackColour.r, db.Colours.StatusBarBackColour.g, db.Colours.StatusBarBackColour.b, db.Colours.StatusBarBackColour.a)
		
		objButton.StatusBar:SetBackdropColor(db.Colours.StatusBarBackColour.r, db.Colours.StatusBarBackColour.g, db.Colours.StatusBarBackColour.b, db.Colours.StatusBarBackColour.a)

		
		objButton.StatusBar.objFontString:SetFont(LSM:Fetch("font", db.Fonts.ScenarioTaskFont), db.Fonts.ScenarioTaskFontSize, db.Fonts.ScenarioHeaderFontOutline)
		if (db.Fonts.ScenarioTaskFontShadowed == true) then
			objButton.StatusBar.objFontString:SetShadowColor(0.0, 0.0, 0.0, 1.0)
		else
			objButton.StatusBar.objFontString:SetShadowColor(0.0, 0.0, 0.0, 0.0)
		end
		
		objButton.StatusBar.objFontString:SetText(self:SecondsToFormatedTime(intTimeLeft))
		
		-- Find out if string is larger then the current largest string
		if (objButton.StatusBar.objFontString:GetWidth() > intLargestWidth) then
			intLargestWidth = objButton.StatusBar.objFontString:GetWidth()
		end
		objButton.StatusBar.objFontString:SetWidth(db.MinionWidth)
		objButton.StatusBar:SetWidth(db.MinionWidth)
		objButton.StatusBar:SetHeight(objButton.StatusBar.objFontString:GetHeight() + 1)	

		
		objButton.StatusBar:SetMinMaxValues(0, intPGDuration);
		objButton.StatusBar:SetValue(intTimeLeft);
		
		intOffset = objButton.StatusBar:GetHeight() + intStatusBarOffset			
		if (objButton.StatusBar:GetWidth() > intLargestWidth) then
			intLargestWidth = objButton.StatusBar:GetWidth()
		end
		intYPosition = intYPosition + intOffset	
		objButtonHeight = objButtonHeight + intOffset;					
			
		objButton:SetHeight(objButtonHeight)				
		tinsert(tblUsingButtons,objButton)	
	end
	
	
	-- Border/Background
	if (blnNothingShown == true) then
		fraMinionAnchor.BorderFrame:SetBackdropColor(db.Colours.MinionBackGroundColour.r, db.Colours.MinionBackGroundColour.g, db.Colours.MinionBackGroundColour.b, 0)
		fraMinionAnchor.BorderFrame:SetBackdropBorderColor(db.Colours.MinionBorderColour.r, db.Colours.MinionBorderColour.g, db.Colours.MinionBorderColour.b, 0)		
	else
		fraMinionAnchor.BorderFrame:SetBackdropColor(db.Colours.MinionBackGroundColour.r, db.Colours.MinionBackGroundColour.g, db.Colours.MinionBackGroundColour.b, db.Colours.MinionBackGroundColour.a)
		fraMinionAnchor.BorderFrame:SetBackdropBorderColor(db.Colours.MinionBorderColour.r, db.Colours.MinionBorderColour.g, db.Colours.MinionBorderColour.b, db.Colours.MinionBorderColour.a)	
		fraMinionAnchor.BorderFrame:SetWidth(intLargestWidth + 16)
		fraMinionAnchor.BorderFrame:SetHeight((intYPosition * db.MinionScale) + 2 + fraMinionAnchor:GetHeight()/2)
	end
	
	blnMinionUpdating = false
end 

function ScenarioTracker:UpdateMinionOnTimer()

	if ((GetTime() - intLastTimerUpdateTime) > 0.5) then
		intElapsedTime = GetTime() - intLastTimerUpdateTime;
		intLastTimerUpdateTime = GetTime()
		
		ScenarioTracker:CheckTimers(GetWorldElapsedTimers());		
		self = ScenarioTracker
		if (strMedal ~= "None") then
			blnMedalNoneUpdateDone = false
			if (blnMinionUpdating == false) then
				self:UpdateMinion()
			end
		end
		
		if (haveBonusTimer == true) then
			if (blnMinionUpdating == false) then
				self:UpdateMinion()
			end		
		end
		
		if(blnInProvingGround == true) then
			ScenarioTracker:UpdateProvingGroundsTimer(intElapsedTime);
			if (blnMinionUpdating == false) then
				self:UpdateMinion()
			end
		end	
		
		if(strMedal == "None" and blnMedalNoneUpdateDone == false and blnMinionUpdating == false) then
			self:UpdateMinion()
		end
	end
end

function ScenarioTracker:CheckTimers(...)
	strMedal = "None"
	intTimeCurrentMedal = 0
	intTimeLeft = 0


	local inChallengeMode = C_Scenario.IsChallengeMode();
	if (not inChallengeMode) then
		return
	end

	for i = 1, select("#", ...) do
		local timerID = select(i, ...);
		
		local _, elapsedTime, timerType = GetWorldElapsedTime(timerID);	
	
		if (timerType == LE_WORLD_ELAPSED_TIMER_TYPE_CHALLENGE_MODE or timerType == LE_WORLD_ELAPSED_TIMER_TYPE_PROVING_GROUND) then
			local _, _, _, _, _, _, _, mapID, _ = GetInstanceInfo();
			if ( mapID ) then
				ScenarioTracker:UpdateTimer(timerID, elapsedTime, GetChallengeModeMapTimes(mapID));
				return;
			end
		end	
	end
end

function ScenarioTracker:UpdateTimer(timerID, elapsedTime, ...)
	local self = ScenarioTracker;
	for i = 1, select("#", ...) do
		tblMedalTimes[i] = select(i, ...);
	end
	
	local intPrevMedalTime = 0
	for i = #tblMedalTimes, 1, -1 do
		local currentMedalTime = tblMedalTimes[i];
		if ( elapsedTime < currentMedalTime ) then
			intTimeCurrentMedal = currentMedalTime - intPrevMedalTime
			intTimeLeft = currentMedalTime - elapsedTime
			strMedal = tblMedals[i]
			break
		else
			intPrevMedalTime = currentMedalTime
		end
	end
end


function ScenarioTracker:UpdateProvingGroundsTimer(elapsedTime)
	intPGElapsedTime = intPGElapsedTime + elapsedTime;
	if (intPGElapsedTime >= intPGDuration) then
		intPGDifficulty = 0;
		intPGCurrentWave = 0;
		intPGMaxWave = 0;
		intPGDuration = 0;
		intPGElapsedTime = 0;
		blnInProvingGround = false;
	end
end

function ScenarioTracker:SecondsToFormatedTime(totalSeconds)
    local mins = math.floor(totalSeconds/60);
	local secs = math.fmod(totalSeconds, 60);
    local hours = math.floor(mins/60); 
	local mins = math.fmod(mins, 60);
	
    return format("%02d:%02d:%02d", hours, mins, secs);
end

--Uniform
function ScenarioTracker:MinionAnchorUpdate(blnMoveAnchors)
	if (blnMinionInitialized == false) then
		if (self:IsVisible() == true) then
			self:CreateMinionLayout()
		end
	end	
	
	if (blnMinionInitialized == true) then
		-- Enable/Disable movement	
		if (db.MinionLocked == false) then
			fraMinionAnchor:EnableMouse(true)
		else
			fraMinionAnchor:EnableMouse(false)
		end
		
		-- Show/Hide Minion
		if (self:IsVisible() == true) then
			fraMinionAnchor:Show()
			if (dbCore.Main.ShowAnchors == true and db.MinionLocked == false) then
				fraMinionAnchor:SetBackdropColor(0, 1, 0, 1)
			else
				fraMinionAnchor:SetBackdropColor(0, 1, 0, 0)
			end
			
			if (blnMinionUpdating == false) then
				self:UpdateMinion()
			end
		else
			fraMinionAnchor:Hide()
		end
		
		-- Set position to stored position
		if (blnMoveAnchors == true) then
			fraMinionAnchor:ClearAllPoints()
			fraMinionAnchor:SetPoint(db.MinionLocation.Point, UIParent, db.MinionLocation.RelativePoint, db.MinionLocation.X, db.MinionLocation.Y);
		end
	end
end

function ScenarioTracker:UpdateColourStrings()
	strMinionTitleColour = format("|c%02X%02X%02X%02X", 255, db.Colours.MinionTitleColour.r * 255, db.Colours.MinionTitleColour.g * 255, db.Colours.MinionTitleColour.b * 255);
	strScenarioHeaderColour = format("|c%02X%02X%02X%02X", 255, db.Colours.ScenarioHeaderColour.r * 255, db.Colours.ScenarioHeaderColour.g * 255, db.Colours.ScenarioHeaderColour.b * 255);
	strScenarioTaskColour = format("|c%02X%02X%02X%02X", 255, db.Colours.ScenarioTaskColour.r * 255, db.Colours.ScenarioTaskColour.g * 255, db.Colours.ScenarioTaskColour.b * 255);
	strScenarioObjectiveColour = format("|c%02X%02X%02X%02X", 255, db.Colours.ScenarioObjectiveColour.r * 255, db.Colours.ScenarioObjectiveColour.g * 255, db.Colours.ScenarioObjectiveColour.b * 255);
end

function ScenarioTracker:HandleColourChanges()
	self:UpdateColourStrings()
	if (self:IsVisible() == true) then
		if (blnMinionUpdating == false) then
			blnMinionUpdating = true
			self:ScheduleTimer("UpdateMinion", 0.1)
		end
	end
end

function ScenarioTracker:ToggleLockState()
	db.MinionLocked = not db.MinionLocked
end

function ScenarioTracker:IsVisible()
	if (self:IsEnabled() == true and dbCore.Main.HideAll == false) then
		return true
	end
	return false	
end