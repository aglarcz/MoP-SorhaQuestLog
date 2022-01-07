local SorhaQuestLog = LibStub("AceAddon-3.0"):GetAddon("SorhaQuestLog")
local L = LibStub("AceLocale-3.0"):GetLocale("SorhaQuestLog")
local MODNAME = "AchievementTracker"
local AchievementsTracker = SorhaQuestLog:NewModule(MODNAME, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0", "LibSink-2.0")

local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local LDB = LibStub:GetLibrary("LibDataBroker-1.1")

local SecondsToTime = SecondsToTime

local fraMinionAnchor = nil
local blnMinionInitialized = false
local blnMinionUpdating = false

local strButtonPrefix = MODNAME .. "Button"


local intNumberUsedButtons = 0
local tblButtonCache = {}
local tblUsingButtons = {}


local strMinionTitleColour = "|cffffffff"
local strAchievementTitleColour = "|cffffffff"
local strAchievementObjectiveColour = "|cffffffff"

local intLastAchievementTimerUpdateTime = 0
local intNumAchievementTimers = 0
local tblAchievementTimers = {}

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
		MaxTasksEachAchievement = 0,
		GrowUpwards = false,
		Fonts = {
			MinionTitleFontSize = 11,
			MinionTitleFont = "framd",
			MinionTitleFontOutline = "",
			MinionTitleFontShadowed = true,
			
			AchievementTitleFontSize = 11,
			AchievementTitleFont = "framd",
			AchievementTitleFontOutline = "",
			AchievementTitleFontShadowed = true,
						
			AchievementObjectiveFontSize = 11,
			AchievementObjectiveFont = "framd",
			AchievementObjectiveFontOutline = "",
			AchievementObjectiveFontShadowed = true,			
		},
		Colours = {
			MinionTitleColour = {r = 0, g = 1, b = 0, a = 1},
			AchievementTitleColour = {r = 0, g = 1, b = 0, a = 1},
			AchievementObjectiveColour = {r = 1, g = 1, b = 1, a = 1},			
			AchievementStatusBarFillColour = {r = 0, g = 1, b = 0, a = 1},
			AchievementStatusBarBackColour = {r = 0, g = 0, b = 0, a = 1},
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
			name = L["Achievement Settings"],
			type = "group",
			childGroups = "tab",
			order = 2,
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
								AchievementsTracker:MinionAnchorUpdate(false)
							end,
						},
						MinionLockedToggle = {
							name = L["Lock Minion"],
							type = "toggle",
							get = function() return db.MinionLocked end,
							set = function()
								db.MinionLocked = not db.MinionLocked
								AchievementsTracker:MinionAnchorUpdate(false)
							end,
							order = 2,
						},
						spacer1 = {
							name = " ",
							type = "description",
							width = "half",
							order = 3,
						},
						ShowTitleToggle = {
							name = L["Show Minion Title"],
							type = "toggle",
							get = function() return db.ShowTitle end,
							set = function()
								db.ShowTitle = not db.ShowTitle
								AchievementsTracker:UpdateMinion()
							end,
							order = 4,
						},
						AutoHideTitleToggle = {
							name = L["Auto Hide Minion Title"],
							desc = L["Hide the title when there is nothing to display"],
							type = "toggle",
							disabled = function() return not(db.ShowTitle) end,
							get = function() return db.AutoHideTitle end,
							set = function()
								db.AutoHideTitle = not db.AutoHideTitle
								AchievementsTracker:UpdateMinion(false)
							end,
							order = 5,
						},
						spacer2 = {
							name = " ",
							type = "description",
							width = "half",
							order = 6,
						},
						GrowUpwardsToggle = {
							name = L["Grow Upwards"],
							desc = L["Minions grows upwards from the anchor"],
							type = "toggle",
							get = function() return db.GrowUpwards end,
							set = function()
								db.GrowUpwards = not db.GrowUpwards
								AchievementsTracker:UpdateMinion()
							end,
							order = 7,
						},						
						CollapseToLeftToggle = {
							name = L["Autoshrink to left"],
							desc = L["Shrinks the width down when the length of current achivements is less then the max width\nNote: Doesn't work well with achivements that wordwrap"],
							type = "toggle",
							get = function() return db.MinionCollapseToLeft end,
							set = function()
								db.MinionCollapseToLeft = not db.MinionCollapseToLeft
								AchievementsTracker:UpdateMinion()
							end,
							order = 8,
						},
						MoveTooltipsRightToggle = {
							name = L["Tooltips on right"],
							desc = L["Moves the tooltips to the right"],
							type = "toggle",
							get = function() return db.MoveTooltipsRight end,
							set = function()
								db.MoveTooltipsRight = not db.MoveTooltipsRight
								AchievementsTracker:UpdateMinion()
							end,
							order = 9,
						},
						MinionWidth = {
							order = 11,
							name = L["Width"],
							desc = L["Adjust the width of the minion"],
							type = "range",
							min = 150, max = 600, step = 1,
							isPercent = false,
							get = function() return db.MinionWidth end,
							set = function(info, value)
								db.MinionWidth = value
								AchievementsTracker:UpdateMinion()
							end,
						},				
						AchievementMinionReset = {
							order = 12,
							type = "execute",
							name = L["Reset Minion Position"],
							desc = L["Resets Achievement Minions position"],
							func = function()
								db.MinionLocation.Point = "CENTER"
								db.MinionLocation.RelativePoint =  "CENTER"
								db.MinionLocation.X = 0
								db.MinionLocation.Y = 0
								AchievementsTracker:MinionAnchorUpdate(true)
							end,
						},
						AchivementsSpacer = {
							name = "   ",
							width = "full",
							type = "description",
							order = 30,
						},
						AchivementsSpacerHeader = {
							name = L["Achievement Settings"],
							type = "header",
							order = 31,
						},
						UseStatusBarsToggle = {
							name = L["Use Bars"],
							desc = L["Uses status bars for achivements with a quanity"],
							type = "toggle",
							get = function() return db.UseStatusBars end,
							set = function()
								db.UseStatusBars = not db.UseStatusBars
								AchievementsTracker:UpdateMinion()
							end,
							order = 32,
						},		
						StatusBarTextureSelect = {
							name = L["Bar Texture"],
							desc = L["The texture the status bars for achievement progress use"],
							type = "select", dialogControl = "LSM30_Statusbar", 
							values = AceGUIWidgetLSMlists.statusbar, 
							disabled = function() return not(db.UseStatusBars) end,
							get = function() return db.StatusBarTexture end,
							set = function(info, value)
								db.StatusBarTexture = value
								AchievementsTracker:UpdateMinion()
							end,
							order = 33,
						},
						MaxNumTasks = {
							order = 34,
							name = L["Tasks # Cap (0 = All)"],
							desc = L["# Tasks shown per Achievement. Set to 0 to display all tasks"],
							type = "range",
							min = 0, max = 20, step = 1,
							isPercent = false,
							get = function() return db.MaxTasksEachAchievement end,
							set = function(info, value)
								db.MaxTasksEachAchievement = value
								if (blnMinionUpdating == false) then
									blnMinionUpdating = true
									AchievementsTracker:ScheduleTimer("UpdateMinion", 0.25)
								end
							end,
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
								AchievementsTracker:UpdateMinion()
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
								AchievementsTracker:UpdateMinion()
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
								AchievementsTracker:UpdateMinion()
							end,
						},
						MinionTitleFontShadowedToggle = {
							name = L["Shadow Text"],
							desc = L["Shows/Hides text shadowing"],
							type = "toggle",
							get = function() return db.Fonts.MinionTitleFontShadowed end,
							set = function()
								db.Fonts.MinionTitleFontShadowed = not db.Fonts.MinionTitleFontShadowed
								AchievementsTracker:UpdateMinion()
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
						AchievementTitleFontSelect = {
							type = "select", dialogControl = 'LSM30_Font',
							order = 52,
							name = L["Font"],
							desc = L["The font used for this element"],
							values = AceGUIWidgetLSMlists.font,
							get = function() return db.Fonts.AchievementTitleFont end,
							set = function(info, value)
								db.Fonts.AchievementTitleFont = value
								AchievementsTracker:UpdateMinion()
							end,
						},
						AchievementTitleFontOutlineSelect = {
							name = L["Font Outline"],
							desc = L["The outline that this font will use"],
							type = "select",
							order = 53,
							values = dicOutlines,
							get = function() return db.Fonts.AchievementTitleFontOutline end,
							set = function(info, value)
								db.Fonts.AchievementTitleFontOutline = value
								AchievementsTracker:UpdateMinion()
							end,
						},
						AchievementTitleFontSizeSize = {
							order = 54,
							name = L["Font Size"],
							desc = L["Controls the font size this font"],
							type = "range",
							min = 8, max = 20, step = 1,
							isPercent = false,
							get = function() return db.Fonts.AchievementTitleFontSize end,
							set = function(info, value)
								db.Fonts.AchievementTitleFontSize = value
								AchievementsTracker:UpdateMinion()
							end,
						},
						AchievementTitleFontShadowedToggle = {
							name = L["Shadow Text"],
							desc = L["Shows/Hides text shadowing"],
							type = "toggle",
							get = function() return db.Fonts.AchievementTitleFontShadowed end,
							set = function()
								db.Fonts.AchievementTitleFontShadowed = not db.Fonts.AchievementTitleFontShadowed
								AchievementsTracker:UpdateMinion()
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
						AchievementObjectiveFontSelect = {
							type = "select", dialogControl = 'LSM30_Font',
							order = 62,
							name = L["Font"],
							desc = L["The font used for this element"],
							values = AceGUIWidgetLSMlists.font,
							get = function() return db.Fonts.AchievementObjectiveFont end,
							set = function(info, value)
								db.Fonts.AchievementObjectiveFont = value
								AchievementsTracker:UpdateMinion()
							end,
						},
						AchievementObjectiveFontOutlineSelect = {
							name = L["Font Outline"],
							desc = L["The outline that this font will use"],
							type = "select",
							order = 63,
							values = dicOutlines,
							get = function() return db.Fonts.AchievementObjectiveFontOutline end,
							set = function(info, value)
								db.Fonts.AchievementObjectiveFontOutline = value
								AchievementsTracker:UpdateMinion()
							end,
						},
						AchievementObjectiveFontSize = {
							order = 64,
							name = L["Font Size"],
							desc = L["Controls the font size this font"],
							type = "range",
							min = 8, max = 20, step = 1,
							isPercent = false,
							get = function() return db.Fonts.AchievementObjectiveFontSize end,
							set = function(info, value)
								db.Fonts.AchievementObjectiveFontSize = value
								AchievementsTracker:UpdateMinion()
							end,
						},
						AchievementObjectiveFontShadowedToggle = {
							name = L["Shadow Text"],
							desc = L["Shows/Hides text shadowing"],
							type = "toggle",
							get = function() return db.Fonts.AchievementObjectiveFontShadowed end,
							set = function()
								db.Fonts.AchievementObjectiveFontShadowed = not db.Fonts.AchievementObjectiveFontShadowed
								AchievementsTracker:UpdateMinion()
							end,
							order = 65,
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
									AchievementsTracker:HandleColourChanges()
								end,
							order = 81,
						},
						AchievementTitleColour = {
							name = L["Achievement Titles"],
							desc = L["Sets the color for Achievement Titles"],
							type = "color",
							hasAlpha = true,
							get = function() return db.Colours.AchievementTitleColour.r, db.Colours.AchievementTitleColour.g, db.Colours.AchievementTitleColour.b, db.Colours.AchievementTitleColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.AchievementTitleColour.r = r
									db.Colours.AchievementTitleColour.g = g
									db.Colours.AchievementTitleColour.b = b
									db.Colours.AchievementTitleColour.a = a
									AchievementsTracker:HandleColourChanges()
								end,
							order = 82,
						},
						AchievementObjectiveColour = {
							name = L["Achievement Task"],
							desc = L["Sets the color for Achievement Objectives"],
							type = "color",
							hasAlpha = true,
							get = function() return db.Colours.AchievementObjectiveColour.r, db.Colours.AchievementObjectiveColour.g, db.Colours.AchievementObjectiveColour.b, db.Colours.AchievementObjectiveColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.AchievementObjectiveColour.r = r
									db.Colours.AchievementObjectiveColour.g = g
									db.Colours.AchievementObjectiveColour.b = b
									db.Colours.AchievementObjectiveColour.a = a
									AchievementsTracker:HandleColourChanges()
								end,
							order = 83,
						},
						AchievementStatusBarFillColour = {
							name = L["Bar Fill Colour"],
							desc = L["Sets the color for the completed part of the achievement status bars"],
							type = "color",
							hasAlpha = true,
							get = function() return db.Colours.AchievementStatusBarFillColour.r, db.Colours.AchievementStatusBarFillColour.g, db.Colours.AchievementStatusBarFillColour.b, db.Colours.AchievementStatusBarFillColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.AchievementStatusBarFillColour.r = r
									db.Colours.AchievementStatusBarFillColour.g = g
									db.Colours.AchievementStatusBarFillColour.b = b
									db.Colours.AchievementStatusBarFillColour.a = a
									AchievementsTracker:UpdateMinion()
								end,
							order = 84,
						},
						AchievementStatusBarBackColour = {
							name = L["Bar Back Colour"],
							desc = L["Sets the color for the un-completed part of the achievement status bars"],
							type = "color",
							hasAlpha = true,
							get = function() return db.Colours.AchievementStatusBarBackColour.r, db.Colours.AchievementStatusBarBackColour.g, db.Colours.AchievementStatusBarBackColour.b, db.Colours.AchievementStatusBarBackColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.AchievementStatusBarBackColour.r = r
									db.Colours.AchievementStatusBarBackColour.g = g
									db.Colours.AchievementStatusBarBackColour.b = b
									db.Colours.AchievementStatusBarBackColour.a = a
									AchievementsTracker:UpdateMinion()
								end,
							order = 85,
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
									AchievementsTracker:HandleColourChanges()
								end,
							order = 86,
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
									AchievementsTracker:HandleColourChanges()
								end,
							order = 87,
						},
					}
				},
			}
		}
	end

	return options
end

--Inits
function AchievementsTracker:OnInitialize()
	self.db = SorhaQuestLog.db:RegisterNamespace(MODNAME, defaults)
	db = self.db.profile
	dbCore = SorhaQuestLog.db.profile
	self:SetEnabledState(SorhaQuestLog:GetModuleEnabled(MODNAME))
	SorhaQuestLog:RegisterModuleOptions(MODNAME, getOptions, L["Achievement Tracker"])
	
	self:UpdateColourStrings()
	self:MinionAnchorUpdate(true)
end

function AchievementsTracker:OnEnable()
	self:RegisterEvent("TRACKED_ACHIEVEMENT_UPDATE")
	self:MinionAnchorUpdate(false)
	self:UpdateMinion()
end

function AchievementsTracker:OnDisable()
	self:UnregisterEvent("TRACKED_ACHIEVEMENT_UPDATE")	
	self:UpdateMinion()
end

function AchievementsTracker:Refresh()
	db = self.db.profile
	dbCore = SorhaQuestLog.db.profile
	
	self:HandleColourChanges()
	self:MinionAnchorUpdate(true)
end

--Events/handlers
function AchievementsTracker:TRACKED_ACHIEVEMENT_UPDATE(...)	
	local achievementID = select(2, ...);
	local elapsed = select(4, ...);
	local duration = select(5, ...);
	if (duration and duration > 0 and (elapsed < duration)) then
		tblAchievementTimers[achievementID] = {["StartTime"] = GetTime(), ["Duration"] = duration, ["TimeLeft"] = duration}
	end
	--self = AchievementsTracker
	if (self:IsVisible() == true) then
		if (blnMinionUpdating == false) then 
			blnMinionUpdating = true
			self:ScheduleTimer("UpdateMinion", 0.1)
		end
	end
end

--Buttons
function AchievementsTracker:GetMinionButton()
	local objButton = SorhaQuestLog:GetLogButton()
	objButton:SetParent(fraMinionAnchor)
	
	-- Create scripts
	objButton:RegisterForClicks("AnyUp")
	objButton:SetScript("OnClick", function(self, button)
		blnWasAClick = true
		if (button == "LeftButton") then
			if (IsShiftKeyDown()) then
				ChatEdit_InsertLink(GetAchievementLink(self.intID))
			else
				if not(AchievementFrame) then
					AchievementFrame_LoadUI();
				end

				if not(AchievementFrame:IsShown()) then
					AchievementFrame_ToggleAchievementFrame();
				end
				AchievementFrame_SelectAchievement(self.intID);
			end
		else
			RemoveTrackedAchievement(self.intID)
		end
	end)
	objButton:SetScript("OnEnter", function(self)
		local strTitle, strObjectives = AchievementsTracker:GetAchievementText(self.intID, true)
		if (db.MoveTooltipsRight == true) then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, -50);
			else 
				GameTooltip:SetOwner(self, "ANCHOR_LEFT", 0, -50);
		end
		GameTooltip:SetText(strTitle, 0, 1, 0, 1);
		GameTooltip:AddLine(strObjectives, 0.5, 0.5, 0.5, 1);
			
		GameTooltip:Show();
	end)
	objButton:SetScript("OnLeave", function(self) 
		GameTooltip:Hide() 
	end)
	
	return objButton
end

function AchievementsTracker:RecycleMinionButton(objButton)
	if (objButton.StatusBar ~= nil) then
		self:RecycleStatusBar(objButton.StatusBar)
		objButton.StatusBar = nil
	end
	SorhaQuestLog:RecycleLogButton(objButton);
end

function AchievementsTracker:GetStatusBar()
	return SorhaQuestLog:GetStatusBar()
end

function AchievementsTracker:RecycleStatusBar(objStatusBar)
	SorhaQuestLog:RecycleStatusBar(objStatusBar)
end

--Minion
function AchievementsTracker:CreateMinionLayout()
	fraMinionAnchor = SorhaQuestLog:doCreateFrame("FRAME","SQLAchievementMinionAnchor",UIParent,100,20,1,"BACKGROUND",1, db.MinionLocation.Point, UIParent, db.MinionLocation.RelativePoint, db.MinionLocation.X, db.MinionLocation.Y, 1)
	fraMinionAnchor:SetMovable(true)
	fraMinionAnchor:SetClampedToScreen(true)
	fraMinionAnchor:RegisterForDrag("LeftButton")
	fraMinionAnchor:SetScript("OnDragStart", fraMinionAnchor.StartMoving)
	fraMinionAnchor:SetScript("OnUpdate", self.UpdateMinionOnTimer)
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
			
			GameTooltip:SetText(L["Achievement Minion Anchor"], 0, 1, 0, 1);
			GameTooltip:AddLine(L["Drag this to move the Achievement minion when it is unlocked.\n"], 1, 1, 1, 1);
			GameTooltip:AddLine(L["You can disable help tooltips in general settings"], 0.5, 0.5, 0.5, 1);
			
			GameTooltip:Show();
		end
	end)
	fraMinionAnchor:SetScript("OnLeave", function(self) 
		GameTooltip:Hide()
	end)
	
	
	fraMinionAnchor:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16, edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,	insets = {left = 5, right = 3, top = 3, bottom = 5}})
	fraMinionAnchor:SetBackdropColor(0, 0, 1, 0)
	fraMinionAnchor:SetBackdropBorderColor(0, 0, 0, 0)

	
	-- Achievements Anchor
	fraMinionAnchor.fraAchievementAnchor = SorhaQuestLog:doCreateLooseFrame("FRAME","SQLQuestsAnchor",fraMinionAnchor, fraMinionAnchor:GetWidth(),1,1,"LOW",1,1)
	fraMinionAnchor.fraAchievementAnchor:SetPoint("TOPLEFT", fraMinionAnchor, "TOPLEFT", 0, 0);
	fraMinionAnchor.fraAchievementAnchor:SetBackdropColor(0, 0, 0, 0)
	fraMinionAnchor.fraAchievementAnchor:SetBackdropBorderColor(0,0,0,0)
	fraMinionAnchor.fraAchievementAnchor:SetAlpha(0)
	
	
	-- Title Fontstring
	fraMinionAnchor.objFontString = fraMinionAnchor:CreateFontString(nil, "OVERLAY");
	fraMinionAnchor.objFontString:SetPoint("TOPLEFT", fraMinionAnchor, "TOPLEFT",0, 0);
	fraMinionAnchor.objFontString:SetFont(LSM:Fetch("font", db.Fonts.MinionTitleFont), db.Fonts.MinionTitleFontSize, db.Fonts.MinionTitleFontOutline)
	if (db.Fonts.MinionTitleFontShadowed == true) then
		fraMinionAnchor.objFontString:SetShadowColor(0.0, 0.0, 0.0, 1.0)
	else
		fraMinionAnchor.objFontString:SetShadowColor(0.0, 0.0, 0.0, 0.0)
	end
	
	fraMinionAnchor.objFontString:SetJustifyH("LEFT")
	fraMinionAnchor.objFontString:SetJustifyV("TOP")
	fraMinionAnchor.objFontString:SetText("");
	fraMinionAnchor.objFontString:SetShadowOffset(1, -1)
	
	fraMinionAnchor.BorderFrame = SorhaQuestLog:doCreateFrame("FRAME","SQLRemoteQuestsMinionBorder", fraMinionAnchor, 100,20,1,"BACKGROUND",1, "TOPLEFT", fraMinionAnchor, "TOPLEFT", -8, 6, 1)
	fraMinionAnchor.BorderFrame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,	insets = {left = 5, right = 3, top = 3, bottom = 5}})
	fraMinionAnchor.BorderFrame:SetBackdropColor(db.Colours.MinionBackGroundColour.r, db.Colours.MinionBackGroundColour.g, db.Colours.MinionBackGroundColour.b, db.Colours.MinionBackGroundColour.a)
	fraMinionAnchor.BorderFrame:SetBackdropBorderColor(db.Colours.MinionBorderColour.r, db.Colours.MinionBorderColour.g, db.Colours.MinionBorderColour.b, db.Colours.MinionBorderColour.a)
	fraMinionAnchor.BorderFrame:Show()
	
	blnMinionInitialized = true
	self:MinionAnchorUpdate(false)
end

function AchievementsTracker:UpdateMinion()
	blnMinionUpdating = true
	
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
	
	-- Kill dead timers dead
	local intAlive = 0
	for k, tblTimer in pairs(tblAchievementTimers) do
		if (tblTimer["TimeLeft"] <= 0) then
			tblAchievementTimers[k] = nil
		else
			intAlive = intAlive + 1
		end
	end
	intNumAchievementTimers = intAlive
	
	local intYPosition = 4
	local intLargestWidth = 0
	local blnNothingShown = false
	
	-- Show title if enabled
	if (db.ShowTitle == true and (db.AutoHideTitle == false or (db.AutoHideTitle == true and (GetNumTrackedAchievements() > 0)))) then
		fraMinionAnchor.objFontString:SetFont(LSM:Fetch("font", db.Fonts.MinionTitleFont), db.Fonts.MinionTitleFontSize, db.Fonts.MinionTitleFontOutline)
		if (db.Fonts.MinionTitleFontShadowed == true) then
			fraMinionAnchor.objFontString:SetShadowColor(0.0, 0.0, 0.0, 1.0)
		else
			fraMinionAnchor.objFontString:SetShadowColor(0.0, 0.0, 0.0, 0.0)
		end
		
		fraMinionAnchor.objFontString:SetText(strMinionTitleColour .. L["Achivement Tracker Title"])
		intLargestWidth = fraMinionAnchor.objFontString:GetWidth()
		
		intYPosition = db.Fonts.MinionTitleFontSize
	else
		blnNothingShown = true
		fraMinionAnchor.objFontString:SetText("")
		intLargestWidth = 100
	end			
	fraMinionAnchor:SetWidth(db.MinionWidth)
	
	
	local intTitleOutlineOffset = 0
	local intObjectiveOutlineOffset = 0
	if (db.Fonts.AchievementTitleFontOutline == "THICKOUTLINE") then
		intTitleOutlineOffset = 2
	elseif (db.Fonts.AchievementTitleFontOutline == "OUTLINE") then
		intTitleOutlineOffset = 1
	end
	if (db.Fonts.AchievementObjectiveFontOutline == "THICKOUTLINE") then
		intObjectiveOutlineOffset = 1.5
	elseif (db.Fonts.AchievementObjectiveFontOutline == "OUTLINE") then
		intObjectiveOutlineOffset = 0.5
	end

	-- Check if there is achievements shown even if titles hidden
	if (GetNumTrackedAchievements() > 0) then
		blnNothingShown = false
	end
		
	-- Create main minions buttons and set text etc	
	local intOffset = 0
	local intInitialYOffset = intYPosition
	local intStatusBarOffset = 2
	local blnFirstAchivement = true
	for _, intID in ipairs({GetTrackedAchievements()}) do
		local strTitle, strObjectives, blnIsQuantity, intHave, intNeed, intValue, intMax = self:GetAchievementText(intID, false)

		-- Get a button for achievement
		local objButton = AchievementsTracker:GetMinionButton()
		objButton.intID = intID
		
		-- Set buttons title text
		objButton.objFontString1:SetPoint("TOPLEFT", objButton, "TOPLEFT", 0, 0);
		objButton.objFontString1:SetFont(LSM:Fetch("font", db.Fonts.AchievementTitleFont), db.Fonts.AchievementTitleFontSize, db.Fonts.AchievementTitleFontOutline)
		if (db.Fonts.AchievementTitleFontShadowed == true) then
			objButton.objFontString1:SetShadowColor(0.0, 0.0, 0.0, 1.0)
		else
			objButton.objFontString1:SetShadowColor(0.0, 0.0, 0.0, 0.0)
		end
		
		objButton.objFontString1:SetText(strTitle)
		
		objButton:SetWidth(db.MinionWidth)

		-- Find out if string is larger then the current largest string
		if (objButton.objFontString1:GetWidth() > intLargestWidth) then
			intLargestWidth = objButton.objFontString1:GetWidth()
		end
		objButton.objFontString1:SetWidth(db.MinionWidth)

		intOffset = objButton.objFontString1:GetHeight() + intTitleOutlineOffset + intObjectiveOutlineOffset
		
		-- Set buttons objective text
		objButton.objFontString2:SetPoint("TOPLEFT", objButton, "TOPLEFT", 0, -intOffset);
		objButton.objFontString2:SetFont(LSM:Fetch("font", db.Fonts.AchievementObjectiveFont), db.Fonts.AchievementObjectiveFontSize, db.Fonts.AchievementObjectiveFontOutline)
		if (db.Fonts.AchievementObjectiveFontShadowed == true) then
			objButton.objFontString2:SetShadowColor(0.0, 0.0, 0.0, 1.0)
		else
			objButton.objFontString2:SetShadowColor(0.0, 0.0, 0.0, 0.0)
		end
		
		objButton.objFontString2:SetText(strObjectives)

		-- Find out if string is larger then the current largest string
		if (objButton.objFontString2:GetWidth() > intLargestWidth) then
			intLargestWidth = objButton.objFontString2:GetWidth()
		end
		objButton.objFontString2:SetWidth(db.MinionWidth)
		
		intOffset = intOffset + objButton.objFontString2:GetHeight() + intTitleOutlineOffset + intObjectiveOutlineOffset

		-- If there is a status bar add one
		if (blnIsQuantity == true and db.UseStatusBars == true) then
			intOffset = intOffset + intStatusBarOffset
			if (objButton.StatusBar == nil) then
				objButton.StatusBar = AchievementsTracker:GetStatusBar()
			end
		
			objButton.StatusBar:Show()
			objButton.StatusBar:SetParent(objButton)
			objButton.StatusBar:SetPoint("TOPLEFT", objButton, "TOPLEFT", 0, -intOffset);
			
			-- Setup colours and texture
			objButton.StatusBar:SetStatusBarTexture(LSM:Fetch("statusbar", db.StatusBarTexture))
			objButton.StatusBar:SetStatusBarColor(db.Colours.AchievementStatusBarFillColour.r, db.Colours.AchievementStatusBarFillColour.g, db.Colours.AchievementStatusBarFillColour.b, db.Colours.AchievementStatusBarFillColour.a)
			
			objButton.StatusBar.Background:SetTexture(LSM:Fetch("statusbar", db.StatusBarTexture))			
			objButton.StatusBar.Background:SetVertexColor(db.Colours.AchievementStatusBarBackColour.r, db.Colours.AchievementStatusBarBackColour.g, db.Colours.AchievementStatusBarBackColour.b, db.Colours.AchievementStatusBarBackColour.a)
			
			objButton.StatusBar:SetBackdropColor(db.Colours.AchievementStatusBarBackColour.r, db.Colours.AchievementStatusBarBackColour.g, db.Colours.AchievementStatusBarBackColour.b, db.Colours.AchievementStatusBarBackColour.a)

			
			objButton.StatusBar.objFontString:SetFont(LSM:Fetch("font", db.Fonts.AchievementObjectiveFont), db.Fonts.AchievementObjectiveFontSize, db.Fonts.AchievementObjectiveFontOutline)
			if (db.Fonts.AchievementObjectiveFontShadowed == true) then
				objButton.StatusBar.objFontString:SetShadowColor(0.0, 0.0, 0.0, 1.0)
			else
				objButton.StatusBar.objFontString:SetShadowColor(0.0, 0.0, 0.0, 0.0)
			end
			
			objButton.StatusBar.objFontString:SetText(intHave .. "/" .. intNeed)
			
			-- Find out if string is larger then the current largest string
			if (objButton.StatusBar.objFontString:GetWidth() > intLargestWidth) then
				intLargestWidth = objButton.StatusBar.objFontString:GetWidth()
			end
			objButton.StatusBar.objFontString:SetWidth(db.MinionWidth)
			objButton.StatusBar:SetWidth(db.MinionWidth)
			objButton.StatusBar:SetHeight(objButton.StatusBar.objFontString:GetHeight() + 1)	

			
			objButton.StatusBar:SetMinMaxValues(0, intMax);
			objButton.StatusBar:SetValue(intValue);

			intOffset = intOffset + objButton.StatusBar:GetHeight() + intTitleOutlineOffset + intObjectiveOutlineOffset + intStatusBarOffset
		else
			if (objButton.StatusBar ~= nil) then
				objButton.StatusBar:Hide()
			end
		end
		
		objButton:SetHeight(intOffset)
		
		-- Set achievements buttons position
		objButton:SetPoint("TOPLEFT", fraMinionAnchor.fraAchievementAnchor, "TOPLEFT", 0, -intYPosition);
		intYPosition = intYPosition + intOffset		
		
		tinsert(tblUsingButtons, objButton)
	end

	local intBorderWidth = db.MinionWidth
	-- Auto collapse
	if (db.MinionCollapseToLeft == true) then
		if (intLargestWidth < db.MinionWidth) then
			fraMinionAnchor:SetWidth(intLargestWidth)
			intBorderWidth = intLargestWidth
			
			for k, objButton in pairs(tblUsingButtons) do
				objButton.objFontString1:SetWidth(intLargestWidth)
				if (objButton.StatusBar ~= nil) then
					objButton.StatusBar.objFontString:SetWidth(intLargestWidth)
					objButton.StatusBar:SetWidth(intLargestWidth)
				end
				
				objButton:SetWidth(intLargestWidth)
			end
		end
	end
	
	
	-- Show border if at least the title is shown
	if (blnNothingShown == true) then
		fraMinionAnchor.BorderFrame:SetBackdropColor(db.Colours.MinionBackGroundColour.r, db.Colours.MinionBackGroundColour.g, db.Colours.MinionBackGroundColour.b, 0)
		fraMinionAnchor.BorderFrame:SetBackdropBorderColor(db.Colours.MinionBorderColour.r, db.Colours.MinionBorderColour.g, db.Colours.MinionBorderColour.b, 0)		
	else
		fraMinionAnchor.BorderFrame:SetBackdropColor(db.Colours.MinionBackGroundColour.r, db.Colours.MinionBackGroundColour.g, db.Colours.MinionBackGroundColour.b, db.Colours.MinionBackGroundColour.a)
		fraMinionAnchor.BorderFrame:SetBackdropBorderColor(db.Colours.MinionBorderColour.r, db.Colours.MinionBorderColour.g, db.Colours.MinionBorderColour.b, db.Colours.MinionBorderColour.a)	
		fraMinionAnchor.BorderFrame:SetWidth(intBorderWidth + 16)
	end
	
	fraMinionAnchor.BorderFrame:ClearAllPoints()
	
	-- Reposition/Resize the border and the Achievements Anchor based on grow upwards option
	if (db.GrowUpwards == false) then
		fraMinionAnchor.BorderFrame:SetPoint("TOPLEFT", fraMinionAnchor.fraAchievementAnchor, "TOPLEFT", -8, 6);
		fraMinionAnchor.BorderFrame:SetHeight(intYPosition + 2 + fraMinionAnchor:GetHeight()/2)
		fraMinionAnchor.fraAchievementAnchor:ClearAllPoints()
		fraMinionAnchor.fraAchievementAnchor:SetPoint("TOPLEFT", fraMinionAnchor, "TOPLEFT", 0, 0);
	else
		fraMinionAnchor.BorderFrame:SetPoint("TOPLEFT", fraMinionAnchor.fraAchievementAnchor, "TOPLEFT", -8,  6 - intInitialYOffset);
		fraMinionAnchor.BorderFrame:SetHeight(intYPosition + 2 + fraMinionAnchor:GetHeight()/2)
		fraMinionAnchor.fraAchievementAnchor:ClearAllPoints()
		fraMinionAnchor.fraAchievementAnchor:SetPoint("TOPLEFT", fraMinionAnchor, "TOPLEFT", 0, intYPosition);
	end

	blnMinionUpdating = false
end 

function AchievementsTracker:UpdateMinionOnTimer()
	self = AchievementsTracker
	if ((GetTime() - intLastAchievementTimerUpdateTime) > 0.5) then
		intLastAchievementTimerUpdateTime = GetTime()
		if (intNumAchievementTimers > 0 and blnMinionUpdating == false) then
			if (self:IsVisible() == true) then
				self:UpdateMinion()
			end
		end
	end
end


-- Achievement information functions
function AchievementsTracker:GetAchievementText(AchievementID, blnAlwaysReturnAll)
	local strOutputTitle = strAchievementTitleColour
	local strOutputObjectives = strAchievementObjectiveColour
	
	local id, name, points, completed, month, day, year, description, flags, icon, rewardText, IsGuild, WasEarnedByMe, EarnedBy = GetAchievementInfo(AchievementID)
	if (name == nil) then
		return "";
	end
	strOutputTitle =  strOutputTitle .. name .. "|r"
	
	
	if (tblAchievementTimers[AchievementID] ~= nil) then
		tblAchievementTimers[AchievementID]["TimeLeft"] = tblAchievementTimers[AchievementID]["Duration"] - (GetTime() - tblAchievementTimers[AchievementID]["StartTime"])

		local strTime = SecondsToTime(tblAchievementTimers[AchievementID]["TimeLeft"])
		if (strTime ~= "") then
			strTime = " - " .. strTime
		else
			strTime = " - 0 Sec"
		end
		
		local r,g,b = GetTimerTextColor(tblAchievementTimers[AchievementID]["Duration"], (GetTime() - tblAchievementTimers[AchievementID]["StartTime"]))
		local strTimeColour = format("|c%02X%02X%02X%02X", 255, r * 255, g * 255, b * 255);
		strOutputTitle = strOutputTitle .. strTimeColour .. strTime .. "|r"
	end
		
	local intNumParts = GetAchievementNumCriteria(AchievementID)
	local blnIsQuantity = false
	local intHave = 0
	local intNeed = 0
	local intValue = 0
	local intMax = 0
	local intDisplayedParts = 0

	if (intNumParts > 0) then
		for i = 1, intNumParts, 1 do
			if (blnAlwaysReturnAll == false) then
				if (intDisplayedParts >= db.MaxTasksEachAchievement and db.MaxTasksEachAchievement > 0) then
					strOutputObjectives = strOutputObjectives .. ".....\n"
					break
				end
			end
			
			local partdescription, atype, completed, quantity, requiredQuantity, characterName, flags, assetID, quantityString, criteriaID = GetAchievementCriteriaInfo(AchievementID, i)
			if (completed == false or quantity < requiredQuantity or atype == 75 or atype == 81 or atype == 156 or atype == 157 or atype == 158 or atype == 160) then
				intDisplayedParts = intDisplayedParts + 1
				if string.match(quantityString, ".+/.+") then
					intHave, intNeed = string.match(quantityString, "(.+)/(.+)")
					string.trim(intNeed)
					
					intValue = quantity
					intMax = requiredQuantity		

					if ( bit.band(flags, EVALUATION_TREE_FLAG_PROGRESS_BAR) == EVALUATION_TREE_FLAG_PROGRESS_BAR ) then
						blnIsQuantity = true
					end

					if (blnIsQuantity == true and db.UseStatusBars == true) then
						strOutputObjectives = strOutputObjectives .. "- " .. description .. "\n"
					else
						strOutputObjectives = strOutputObjectives .. "- " .. intHave .. "/" .. intNeed .. "\n"
					end
				else
					strOutputObjectives = strOutputObjectives .. "- " .. partdescription .. "\n"
				end
			end
		end
	else
		strOutputObjectives = strOutputObjectives .. "- " .. description
	end
	strOutputObjectives = string.trim(strOutputObjectives)
	strOutputObjectives = strOutputObjectives .. "|r"
	
	return strOutputTitle, strOutputObjectives, blnIsQuantity, intHave, intNeed, intValue, intMax
end

function GetTimerTextColor(duration, elapsed) -- Thankyou blizzard >.>
	local START_PERCENTAGE_YELLOW = .66
	local START_PERCENTAGE_RED = .33
	
	local percentageLeft = 1 - ( elapsed / duration )
	if ( percentageLeft > START_PERCENTAGE_YELLOW ) then
		return 1, 1, 1	
	elseif ( percentageLeft > START_PERCENTAGE_RED ) then -- Start fading to yellow by eliminating blue
		local blueOffset = (percentageLeft - START_PERCENTAGE_RED) / (START_PERCENTAGE_YELLOW - START_PERCENTAGE_RED);
		return 1, 1, blueOffset;
	else
		local greenOffset = percentageLeft / START_PERCENTAGE_RED; -- Fade to red by eliminating green
		return 1, greenOffset, 0;
	end
end

--Uniform
function AchievementsTracker:MinionAnchorUpdate(blnMoveAnchors)
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
		if (self:IsVisible() == true and dbCore.Main.HideAll == false) then
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

function AchievementsTracker:UpdateColourStrings()
	strMinionTitleColour = format("|c%02X%02X%02X%02X", 255, db.Colours.MinionTitleColour.r * 255, db.Colours.MinionTitleColour.g * 255, db.Colours.MinionTitleColour.b * 255);
	strAchievementTitleColour = format("|c%02X%02X%02X%02X", 255, db.Colours.AchievementTitleColour.r * 255, db.Colours.AchievementTitleColour.g * 255, db.Colours.AchievementTitleColour.b * 255);
	strAchievementObjectiveColour = format("|c%02X%02X%02X%02X", 255, db.Colours.AchievementObjectiveColour.r * 255, db.Colours.AchievementObjectiveColour.g * 255, db.Colours.AchievementObjectiveColour.b * 255);
end

function AchievementsTracker:HandleColourChanges()
	self:UpdateColourStrings()
	if (self:IsVisible() == true) then
		if (blnMinionUpdating == false) then
			blnMinionUpdating = true
			self:ScheduleTimer("UpdateMinion", 0.1)
		end
	end
end

function AchievementsTracker:ToggleLockState()
	db.MinionLocked = not db.MinionLocked
end

function AchievementsTracker:IsVisible()
	if (self:IsEnabled() == true and dbCore.Main.HideAll == false) then
		return true
	end
	return false	
end