local SorhaQuestLog = LibStub("AceAddon-3.0"):GetAddon("SorhaQuestLog")
local L = LibStub("AceLocale-3.0"):GetLocale("SorhaQuestLog")
local MODNAME = "QuestTimersTracker"
local QuestTimersTracker = SorhaQuestLog:NewModule(MODNAME, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0", "LibSink-2.0")

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
local strQuestTextFontColour = "|cffffffff"
local intLastOnUpdateTime = 0 -- Time OnUpdate event was last used

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
		Fonts = {
			-- Scenario minion title font
			MinionTitleFontSize = 11,
			MinionTitleFont = "framd",
			MinionTitleFontOutline = "",
			MinionTitleFontShadowed = true,
			
			-- Scenario header font
			QuestTextFontSize = 11,
			QuestTextHeaderFont = "framd",
			QuestTextHeaderFontOutline = "",
			QuestTextHeaderFontShadowed = true,
		},
		Colours = {
			MinionTitleColour = {r = 0, g = 1, b = 0, a = 1},
			QuestTextHeaderColour = {r = 1, g = 1, b = 1, a = 1},
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
			name = L["Quest Timers"],
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
								QuestTimersTracker:MinionAnchorUpdate(false)
							end,
						},						
						MinionLockedToggle = {
							name = L["Lock Minion"],
							type = "toggle",
							get = function() return db.MinionLocked end,
							set = function()
								db.MinionLocked = not db.MinionLocked
								QuestTimersTracker:MinionAnchorUpdate(false)
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
								QuestTimersTracker:UpdateMinion()
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
								QuestTimersTracker:UpdateMinion(false)
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
								QuestTimersTracker:UpdateMinion()
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
								QuestTimersTracker:UpdateMinion()
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
								QuestTimersTracker:UpdateMinion()
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
								QuestTimersTracker:UpdateMinion()
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
								QuestTimersTracker:UpdateMinion()
							end,
						},
						MinionTitleFontShadowedToggle = {
							name = L["Shadow Text"],
							desc = L["Shows/Hides text shadowing"],
							type = "toggle",
							get = function() return db.Fonts.MinionTitleFontShadowed end,
							set = function()
								db.Fonts.MinionTitleFontShadowed = not db.Fonts.MinionTitleFontShadowed
								QuestTimersTracker:UpdateMinion()
							end,
							order = 45,
						},
						QuestTextFontsSpacer = {
							name = "   ",
							width = "full",
							type = "description",
							order = 50,
						},
						QuestTextFonts = {
							name = L["Quest Timer Text Font Settings"],
							type = "header",
							order = 51,
						},
						QuestTextFontSelect = {
							type = "select", dialogControl = 'LSM30_Font',
							order = 52,
							name = L["Font"],
							desc = L["The font used for this element"],
							values = AceGUIWidgetLSMlists.font,
							get = function() return db.Fonts.QuestTextHeaderFont end,
							set = function(info, value)
								db.Fonts.QuestTextHeaderFont = value
								QuestTimersTracker:UpdateMinion()
							end,
						},
						QuestTextFontOutlineSelect = {
							name = L["Font Outline"],
							desc = L["The outline that this font will use"],
							type = "select",
							order = 53,
							values = dicOutlines,
							get = function() return db.Fonts.QuestTextHeaderFontOutline end,
							set = function(info, value)
								db.Fonts.QuestTextHeaderFontOutline = value
								QuestTimersTracker:UpdateMinion()
							end,
						},
						QuestTextFontSize = {
							order = 54,
							name = L["Font Size"],
							desc = L["Controls the font size this font"],
							type = "range",
							min = 8, max = 20, step = 1,
							isPercent = false,
							get = function() return db.Fonts.QuestTextFontSize end,
							set = function(info, value)
								db.Fonts.QuestTextFontSize = value
								QuestTimersTracker:UpdateMinion()
							end,
						},
						QuestTextFontShadowedToggle = {
							name = L["Shadow Text"],
							desc = L["Shows/Hides text shadowing"],
							type = "toggle",
							get = function() return db.Fonts.QuestTextHeaderFontShadowed end,
							set = function()
								db.Fonts.QuestTextHeaderFontShadowed = not db.Fonts.QuestTextHeaderFontShadowed
								QuestTimersTracker:UpdateMinion()
							end,
							order = 55,
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
									QuestTimersTracker:HandleColourChanges()
								end,
							order = 81,
						},
						QuestTextColour = {
							name = L["Quest Texts"],
							desc = L["Sets the color for Quest Texts"],
							type = "color",
							hasAlpha = true,
							get = function() return db.Colours.QuestTextHeaderColour.r, db.Colours.QuestTextHeaderColour.g, db.Colours.QuestTextHeaderColour.b, db.Colours.QuestTextHeaderColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.QuestTextHeaderColour.r = r
									db.Colours.QuestTextHeaderColour.g = g
									db.Colours.QuestTextHeaderColour.b = b
									db.Colours.QuestTextHeaderColour.a = a
									QuestTimersTracker:HandleColourChanges()
								end,
							order = 82,
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
									QuestTimersTracker:HandleColourChanges()
								end,
							order = 85,
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
									QuestTimersTracker:HandleColourChanges()
								end,
							order = 86,
						},
					}
				},
			}
		}
	end


	return options
end

--Inits
function QuestTimersTracker:OnInitialize()
	self.db = SorhaQuestLog.db:RegisterNamespace(MODNAME, defaults)
	db = self.db.profile
	dbCore = SorhaQuestLog.db.profile
	self:SetEnabledState(SorhaQuestLog:GetModuleEnabled(MODNAME))
	SorhaQuestLog:RegisterModuleOptions(MODNAME, getOptions, L["Quest Timers Tracker"])
	
	self:UpdateColourStrings()
	self:MinionAnchorUpdate(true)
end

function QuestTimersTracker:OnEnable()
	--setup the update in anchor
end

function QuestTimersTracker:OnDisable()
	--disable update in anchor
end

function QuestTimersTracker:Refresh()
	db = self.db.profile
	dbCore = SorhaQuestLog.db.profile
	
	self:HandleColourChanges()
	self:MinionAnchorUpdate(true)
end

--Events/handlers

--Buttons
function QuestTimersTracker:GetMinionButton()
	return SorhaQuestLog:GetLogButton();
end

function QuestTimersTracker:RecycleMinionButton(objButton)
	SorhaQuestLog:RecycleLogButton(objButton);
end

--Minion
function QuestTimersTracker:CreateMinionLayout()
	-- Timer anchor
	fraMinionAnchor = SorhaQuestLog:doCreateFrame("FRAME","SQLQuestTimerAnchor",UIParent,100,20,1,"BACKGROUND",1, db.MinionLocation.Point, UIParent, db.MinionLocation.RelativePoint, db.MinionLocation.X, db.MinionLocation.Y, 1)
	fraMinionAnchor:SetMovable(true)
	fraMinionAnchor:SetClampedToScreen(true)
	fraMinionAnchor:RegisterForDrag("LeftButton")
	fraMinionAnchor:SetScript("OnDragStart", fraMinionAnchor.StartMoving)
	fraMinionAnchor:SetScript("OnUpdate", self.UpdateMinion)
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
			if (db.MoveTooltipsRight == true) then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0);
			else 
				GameTooltip:SetOwner(self, "ANCHOR_LEFT", 0, 0);
			end
			
			GameTooltip:SetText(L["Quest Timer Minion Anchor"], 0, 1, 0, 1);
			GameTooltip:AddLine(L["Drag this to move the Quest Timer minion when it is unlocked.\n"], 1, 1, 1, 1);
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

	-- Timer fontstring for title "Quest Timer"
	fraMinionAnchor.objFontString = fraMinionAnchor:CreateFontString(nil, "OVERLAY");
	fraMinionAnchor.objFontString:SetPoint("TOPLEFT", fraMinionAnchor, "TOPLEFT",0, 0);
	fraMinionAnchor.objFontString:SetFont(LSM:Fetch("font", db.Fonts.MinionTitleFont), db.Fonts.MinionTitleFontSize, db.Fonts.MinionTitleFontOutline)
	if (db.Fonts.QuestMinionTitleFontShadowed == true) then
		fraMinionAnchor.objFontString:SetShadowColor(0.0, 0.0, 0.0, 1.0)
	else
		fraMinionAnchor.objFontString:SetShadowColor(0.0, 0.0, 0.0, 0.0)
	end
	
	fraMinionAnchor.objFontString:SetJustifyH("LEFT")
	fraMinionAnchor.objFontString:SetJustifyV("TOP")
	fraMinionAnchor.objFontString:SetText("");
	fraMinionAnchor.objFontString:SetShadowOffset(1, -1)
	
	fraMinionAnchor.BorderFrame = SorhaQuestLog:doCreateFrame("FRAME","SQLQuestTimerMinionBorder", fraMinionAnchor, 100,20,1,"BACKGROUND",1, "TOPLEFT", fraMinionAnchor, "TOPLEFT", -6, 6, 1)
	fraMinionAnchor.BorderFrame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,	insets = {left = 5, right = 3, top = 3, bottom = 5}})
	fraMinionAnchor.BorderFrame:SetBackdropColor(db.Colours.MinionBackGroundColour.r, db.Colours.MinionBackGroundColour.g, db.Colours.MinionBackGroundColour.b, db.Colours.MinionBackGroundColour.a)
	fraMinionAnchor.BorderFrame:SetBackdropBorderColor(db.Colours.MinionBorderColour.r, db.Colours.MinionBorderColour.g, db.Colours.MinionBorderColour.b, db.Colours.MinionBorderColour.a)
	fraMinionAnchor.BorderFrame:Show()
	
	blnMinionInitialized = true
	self:MinionAnchorUpdate(false)
end

function QuestTimersTracker:UpdateMinion()
	-- If half a second is past and timer shown, (then if timer not started create), then refresh
	if ((GetTime() - intLastOnUpdateTime) > 0.5) then
		intLastOnUpdateTime = GetTime()
	else
		return ""
	end	
	
	blnMinionUpdating = true
	if (blnMinionInitialized == false) then
		QuestTimersTracker:CreateMinionLayout()
	end
	if (QuestTimersTracker:IsVisible() == false) then
		blnMinionUpdating = false
		return ""
	end
	
	-- Release all used buttons
	for k, objButton in pairs(tblUsingButtons) do
		QuestTimersTracker:RecycleMinionButton(objButton)
	end
	wipe(tblUsingButtons)
			
	local timers = GetQuestTimers()
	local numTimers = 0;
	if (timers ~= nil) then
		numTimers = select("#", timers);
	end
	local dblYPosition = db.Fonts.MinionTitleFontSize
	local dblOffset = 0
	local intLargestWidth = 0
		
	local blnNothingShown = false
	-- Show title if enabled
	if (db.ShowTitle == true and (db.AutoHideTitle == false or (db.AutoHideTitle == true and (numTimers > 0)))) then
		fraMinionAnchor.objFontString:SetFont(LSM:Fetch("font", db.Fonts.MinionTitleFont), db.Fonts.MinionTitleFontSize, db.Fonts.MinionTitleFontOutline)
		if (db.Fonts.MinionTitleFontShadowed == true) then
			fraMinionAnchor.objFontString:SetShadowColor(0.0, 0.0, 0.0, 1.0)
		else
			fraMinionAnchor.objFontString:SetShadowColor(0.0, 0.0, 0.0, 0.0)
		end
		
		fraMinionAnchor.objFontString:SetText(strMinionTitleColour .. L["Quest Timer Frame Title"] .. "|r")
	
		if (intLargestWidth < fraMinionAnchor.objFontString:GetStringWidth()) then
			intLargestWidth = fraMinionAnchor.objFontString:GetStringWidth()
		end
	else
		blnNothingShown = true
		fraMinionAnchor.objFontString:SetText("")
	end	
	
	-- Create timers
	for i = 1, numTimers do
		local objButton = QuestTimersTracker:GetMinionButton()
		objButton:SetPoint("TOPLEFT", fraMinionAnchor, "TOPLEFT", 0, -dblYPosition);
		
		-- Set buttons text
		objButton.objFontString1:SetFont(LSM:Fetch("font", db.Fonts.QuestTextHeaderFont), db.Fonts.QuestTextFontSize, db.Fonts.QuestTextHeaderFontOutline)
		if (db.Fonts.QuestTextHeaderFontShadowed == true) then
			objButton.objFontString1:SetShadowColor(0.0, 0.0, 0.0, 1.0)
		else
			objButton.objFontString1:SetShadowColor(0.0, 0.0, 0.0, 0.0)
		end
		
		objButton.objFontString1:SetPoint("TOPLEFT", objButton, "TOPLEFT", 0, 0);
		objButton.objFontString1:SetText(strQuestTextFontColour .. " - " .. SecondsToTime(select(i, timers)) .. "|r")
		
		-- Get offset for next button
		dblOffset = objButton.objFontString1:GetStringHeight()	
		
		if (intLargestWidth < objButton.objFontString1:GetStringWidth()) then
			intLargestWidth = objButton.objFontString1:GetStringWidth()
		end
		
		-- Set Height and Width
		objButton:SetHeight(dblOffset)
		objButton:SetWidth(objButton.objFontString1:GetStringWidth())
		
		-- Setup scripts
		objButton:SetScript("OnEnter", function (self) GameTooltip:SetOwner(self); GameTooltip:SetHyperlink(GetQuestLink(GetQuestIndexForTimer(i))); GameTooltip:Show(); end);
		objButton:SetScript("OnLeave", GameTooltip_Hide);
		
		dblYPosition = dblYPosition + dblOffset
		tinsert(tblUsingButtons, objButton)
	end

	
	-- Border/Background
	if (blnNothingShown == true) then
		fraMinionAnchor.BorderFrame:SetBackdropColor(db.Colours.MinionBackGroundColour.r, db.Colours.MinionBackGroundColour.g, db.Colours.MinionBackGroundColour.b, 0)
		fraMinionAnchor.BorderFrame:SetBackdropBorderColor(db.Colours.MinionBorderColour.r, db.Colours.MinionBorderColour.g, db.Colours.MinionBorderColour.b, 0)		
	else
		fraMinionAnchor.BorderFrame:SetBackdropColor(db.Colours.MinionBackGroundColour.r, db.Colours.MinionBackGroundColour.g, db.Colours.MinionBackGroundColour.b, db.Colours.MinionBackGroundColour.a)
		fraMinionAnchor.BorderFrame:SetBackdropBorderColor(db.Colours.MinionBorderColour.r, db.Colours.MinionBorderColour.g, db.Colours.MinionBorderColour.b, db.Colours.MinionBorderColour.a)	
		fraMinionAnchor.BorderFrame:SetWidth(intLargestWidth + 16)
		fraMinionAnchor.BorderFrame:SetHeight((dblYPosition * db.MinionScale) + 2 + fraMinionAnchor:GetHeight()/2)
	end

	blnMinionUpdating = false
end 

--Uniform
function QuestTimersTracker:MinionAnchorUpdate(blnMoveAnchors)
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

function QuestTimersTracker:UpdateColourStrings()
	strMinionTitleColour = format("|c%02X%02X%02X%02X", 255, db.Colours.MinionTitleColour.r * 255, db.Colours.MinionTitleColour.g * 255, db.Colours.MinionTitleColour.b * 255);
	strQuestTextFontColour = format("|c%02X%02X%02X%02X", 255, db.Colours.QuestTextHeaderColour.r * 255, db.Colours.QuestTextHeaderColour.g * 255, db.Colours.QuestTextHeaderColour.b * 255);
end

function QuestTimersTracker:HandleColourChanges()
	self:UpdateColourStrings()
	if (self:IsVisible() == true) then
		if (blnMinionUpdating == false) then
			blnMinionUpdating = true
			self:ScheduleTimer("UpdateMinion", 0.1)
		end
	end
end

function QuestTimersTracker:ToggleLockState()
	db.MinionLocked = not db.MinionLocked
end

function QuestTimersTracker:IsVisible()
	if (self:IsEnabled() == true and dbCore.Main.HideAll == false) then
		return true
	end
	return false	
end