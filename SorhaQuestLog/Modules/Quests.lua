local SorhaQuestLog = LibStub("AceAddon-3.0"):GetAddon("SorhaQuestLog")
local L = LibStub("AceLocale-3.0"):GetLocale("SorhaQuestLog")
local MODNAME = "QuestTracker"
local QuestTracker = SorhaQuestLog:NewModule(MODNAME, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0", "LibSink-2.0")

local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local LDB = LibStub:GetLibrary("LibDataBroker-1.1")

local fraMinionAnchor = nil
local blnMinionInitialized = false
local blnMinionUpdating = false

local strButtonPrefix = MODNAME .. "Button"
local strItemButtonPrefix = MODNAME .. "ItemButton"
local intNumberUsedButtons = 0
local intNumberOfItemButtons = 0

local tblButtonCache = {}
local tblItemButtonCache = {}
local tblUsingButtons = {}

local strMinionTitleColour = "|cffffffff"
local strInfoColour = "|cffffffff"
local strHeaderColour = "|cffffffff"
local strQuestTitleColour = "|cffffffff"
local strObjectiveTitleColour = "|cffffffff"
local strObjectiveDescriptionColour = "|cffffffff"
local strQuestStatusFailed = "|cffffffff"
local strQuestStatusDone = "|cffffffff"
local strQuestStatusGoto = "|cffffffff"
local strQuestLevelColour = "|cffffffff"
local strObjectiveStatusColour = "|cffffffff"
local strObjective00to24Colour = "|cffffffff"
local strObjective25to49Colour = "|cffffffff"
local strObjective50to74Colour = "|cffffffff"
local strObjective75to99Colour = "|cffffffff"
local strObjective100Colour = "|cffffffff"
local strObjectiveTooltipTextColour = "|cffffffff"

local intItemButtonSize = 26

-- Tables
local tblBagsToCheck = {}
local tblHaveQuestItems = {}

local blnWasAClick = false -- Was QUEST_LOG_UPDATE called by a click on a header etc
local blnIgnoreUpdateEvents = false -- Ignores QLU events, used when making large scale collapse/expands to log
local blnFirstUpdate = true -- Was first update of quest log, no old data will be on store yet
local blnFirstBagCheck = true
local blnHaveRefreshedHeaders = false

local blnBagCheckUpdating = false
local blnHaveRegisteredBagUpdate = false


-- Strings used to store current location for auto collapse/expand
local strZone = ""
local strSubZone = ""

local curQuestInfo = nil -- Questlog data stores
local oldQuestInfo = nil -- Questlog data stores
local intTimeOfLastSound = 0 -- Time last sound played

-- Matching quest completion outputs
local function getPattern(strPattern)
	strPattern = string.gsub(strPattern, "%(", "%%%1")
	strPattern = string.gsub(strPattern, "%)", "%%%1")
	strPattern = string.gsub(strPattern, "%%%d?$?.", "(.+)")
	return format("^%s$", strPattern)
end

local tblQuestMatchs = {
	["Found"] = getPattern(ERR_QUEST_ADD_FOUND_SII),
	["Item"] = getPattern(ERR_QUEST_ADD_ITEM_SII),
	["Kill"] = getPattern(ERR_QUEST_ADD_KILL_SII),
	["PKill"] = getPattern(ERR_QUEST_ADD_PLAYER_KILL_SII),
	["ObjectiveComplete"] = getPattern(ERR_QUEST_OBJECTIVE_COMPLETE_S),
	["QuestComplete"] = getPattern(ERR_QUEST_COMPLETE_S),
	["QuestFailed"] = getPattern(ERR_QUEST_FAILED_S),
}

-- Tables used for quest tags (Group, Elite etc)
local dicQuestTags = {
	[ELITE] = "+",
	[GROUP] = "g",
	[PVP] = "p",
	[RAID] = "r",
	[LFG_TYPE_DUNGEON] = "d",
	[PLAYER_DIFFICULTY2] = "d+",
	["Daily"] = "*",
}

local dicLongQuestTags = {

	[ELITE] = ELITE,
	[GROUP] = GROUP,
	[PVP] = PVP,
	[RAID] = RAID,
	[LFG_TYPE_DUNGEON] = LFG_TYPE_DUNGEON,
	[PLAYER_DIFFICULTY2] = PLAYER_DIFFICULTY2,
	["Daily"] = L["Daily"],
}

local dicRepLevels = {
	["Hated"] = {["MTitle"] = FACTION_STANDING_LABEL1, ["FTitle"] = FACTION_STANDING_LABEL1_FEMALE, ["Value"] = 1.00},
	["Hostile"] = {["MTitle"] = FACTION_STANDING_LABEL2, ["FTitle"] = FACTION_STANDING_LABEL2_FEMALE, ["Value"] = 1.30},
	["Unfriendly"] = {["MTitle"] = FACTION_STANDING_LABEL3, ["FTitle"] = FACTION_STANDING_LABEL3_FEMALE, ["Value"] = 1.70},
	["Neutral"] = {["MTitle"] = FACTION_STANDING_LABEL4, ["FTitle"] = FACTION_STANDING_LABEL4_FEMALE, ["Value"] = 2.20},
	["Friendly"] = {["MTitle"] = FACTION_STANDING_LABEL5, ["FTitle"] = FACTION_STANDING_LABEL5_FEMALE, ["Value"] = 2.85},
	["Honored"] = {["MTitle"] = FACTION_STANDING_LABEL6, ["FTitle"] = FACTION_STANDING_LABEL6_FEMALE, ["Value"] = 3.71},
	["Revered"] = {["MTitle"] = FACTION_STANDING_LABEL7, ["FTitle"] = FACTION_STANDING_LABEL7_FEMALE, ["Value"] = 4.82},
	["Exalted"] = {["MTitle"] = FACTION_STANDING_LABEL8, ["FTitle"] = FACTION_STANDING_LABEL8_FEMALE, ["Value"] = 6.27},
}

--options table helpers
local dicOutlines = {
	[""] = L["None"],
	["OUTLINE"] = L["Outline"],
	["THICKOUTLINE"] = L["Thick Outline"],
}

local dicQuestTitleColourOptions = {
	["Custom"] = L["Custom"],
	["Level"] = L["Level"],
	["Completion"] = L["Completion"],
	["Done/Undone"] = L["Done/Undone"],
}

local dicObjectiveColourOptions = {
	["Custom"] = L["Custom"],
	["Done/Undone"] = L["Done/Undone"],
	["Completion"] = L["Completion"],
}

local dicNotificationColourOptions = {
	["Custom"] = L["Custom"],
	["Completion"] = L["Completion"],
}

local dicQuestTags = {
	[ELITE] = "+",
	[GROUP] = "g",
	[PVP] = "p",
	[RAID] = "r",
	[LFG_TYPE_DUNGEON] = "d",
	[PLAYER_DIFFICULTY2] = "d+",
	["Daily"] = "*",
}

local dicQuestTagsLength = {
	["None"] = L["None"],
	["Short"] = L["Short"],
	["Full"] = L["Full"],
}

--Defaults
local db
local dbCore
local dbChar
local defaults = {
	profile = {
		MinionLocation = {X = 0, Y = 0, Point = "CENTER", RelativePoint = "CENTER"},
		MinionScale = 1,
		MinionLocked = false,
		MinionWidth = 220,
		AutoHideTitle = false,
		MinionCollapseToLeft = false,
		MoveTooltipsRight = false,		
		GrowUpwards = false,
		ConfirmQuestAbandons = true,
		ShowNumberOfQuests = true,
		ShowNumberOfDailyQuests = false,		
		ShowItemButtons = true,
		IndentItemButtons = false,
		IndentItemButtonQuestsOnly = false,			
		ItemButtonScale = 0.8,
		HideItemButtonsForCompletedQuests = true,		
		ZonesAndQuests = {
			QuestLevelColouringSetting = "Level",
			QuestTitleColouringSetting = "Level",
			ObjectiveTitleColouringSetting = "Custom",
			ObjectiveStatusColouringSetting = "Completion",
			QuestTagsLength = "Short",
			ShowQuestLevels = true,
			HideCompletedObjectives = true,
			HideCompletedQuests = false,
			ShowDescWhenNoObjectives = false,
			AllowHiddenQuests = true,
			CollapseOnLeave = false,
			ExpandOnEnter = false,
			HideZoneHeaders = false,
			QuestHeadersHideWhenEmpty = true,
			ShowHiddenCountOnZones = false,
			QuestTitleIndent = 5,
			ObjectivesIndent = 0,
			QuestClicksOpenFullQuestLog = true,
			QuestAfterPadding = 0,
		},		
		Sounds = {
			UseQuestDoneSound = false,
			UseObjectiveDoneSound = false,
		},
		Fonts = {
			-- Scenario minion title font
			MinionTitleFontSize = 11,
			MinionTitleFont = "framd",
			MinionTitleFontOutline = "",
			MinionTitleFontShadowed = true,
			MinionTitleFontLineSpacing = 0,
			
			-- Zone header font
			HeaderFontSize = 11,
			HeaderFont = "framd",
			HeaderFontOutline = "",
			HeaderFontShadowed = true,
			HeaderFontLineSpacing = 0,
				
			-- Quest title font
			QuestFontSize = 11,
			QuestFont = "framd",
			QuestFontOutline = "",
			QuestFontShadowed = true,
			QuestFontLineSpacing = 0,
			
			-- Objective text font
			ObjectiveFontSize = 11,
			ObjectiveFont = "framd",
			ObjectiveFontOutline = "",
			ObjectiveFontShadowed = true,
			ObjectiveFontLineSpacing = 0,
			
		},
		Colours = {
			MinionTitleColour = {r = 0, g = 1, b = 0, a = 1},
			HeaderColour = {r = 0, g = 0.6, b = 1, a = 1},
			QuestTitleColour = {r = 1, g = 1, b = 1, a = 1},
			ObjectiveDescColour = {r = 0.5, g = 0.5, b = 0.5, a = 0.5},
			ObjectiveTitleColour = {r = 1, g = 1, b = 1, a = 1},			
			QuestStatusFailedColour = {r = 1, g = 1, b = 1, a = 1},
			QuestStatusDoneColour = {r = 1, g = 1, b = 1, a = 1},
			QuestStatusGotoColour = {r = 1, g = 1, b = 1, a = 1},
			QuestLevelColour = {r = 1, g = 1, b = 1, a = 1},
			ObjectiveStatusColour = {r = 1, g = 1, b = 1, a = 1},
			Objective00PlusColour = {r = 1, g = 0, b = 0, a = 1},
			Objective25PlusColour = {r = 1, g = 0.3, b = 0, a = 1},
			Objective50PlusColour  = {r = 1, g = 0.6, b = 0, a = 1},
			Objective75PlusColour = {r = 1, g = 0.95, b = 0, a = 1},
			ObjectiveDoneColour = {r = 0, g = 1, b = 0, a = 1},			
			MinionBackGroundColour = {r = 0.5, g = 0.5, b = 0.5, a = 0},
			MinionBorderColour = {r = 0.5, g = 0.5, b = 0.5, a = 0},
			InfoColour = {r = 0, g = 1, b = 0.5, a = 1},
			NotificationsColour = {r = 0, g = 1, b = 0, a = 1},
			ObjectiveTooltipTextColour = {r = 0.5, g = 0.5, b = 0.5, a = 1},
		},
		Notifications = {
			LibSinkColourSetting = "Custom",
			SuppressBlizzardNotifications = false,
			LibSinkObjectiveNotifications = false,
			DisplayQuestOnObjectiveNotifications = true,
			ShowQuestCompletesAndFails = false,
			QuestDoneSound = "None",
			ObjectiveDoneSound = "None",
			QuestItemFoundSound = "None",
			ShowMessageOnPickingUpQuestItem = false,
		},
	},
	char = {
		ZoneIsAllHiddenQuests = {},
		ZoneIsCollapsed = {},
		ZonesAndQuests = {
			ShowAllQuests = false,
		}
	},
}

--Options
local options
local function getOptions()
	if not options then
		options = {
			name = L["Quest Tracker Settings"],
			type = "group",
			childGroups = "tab",
			order = 1,
			arg = MODNAME,
			args = {
				Main = {
					name = L["Main"],
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
								QuestTracker:MinionAnchorUpdate(false)
							end,
						},				
						MinionLockedToggle = {
							name = L["Lock Minion"],
							type = "toggle",
							get = function() return db.MinionLocked end,
							set = function()
								db.MinionLocked = not db.MinionLocked
								QuestTracker:MinionAnchorUpdate(false)
							end,
							order = 2,
						},
						AutoHideTitleToggle = {
							name = L["Auto Hide Minion Title"],
							desc = L["Hide the title when there is nothing to display"],
							type = "toggle",
							get = function() return db.AutoHideTitle end,
							set = function()
								db.AutoHideTitle = not db.AutoHideTitle
								QuestTracker:UpdateMinion()
							end,
							order = 5,
						},
						GrowUpwardsToggle = {
							name = L["Grow Upwards"],
							desc = L["Minions grows upwards from the anchor"],
							type = "toggle",
							get = function() return db.GrowUpwards end,
							set = function()
								db.GrowUpwards = not db.GrowUpwards
								QuestTracker:UpdateMinion()
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
								QuestTracker:UpdateMinion()
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
								QuestTracker:UpdateMinion()
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
								QuestTracker:UpdateMinion()
							end,
						},
						Reset = {
							order = 12,
							type = "execute",
							name = L["Reset Main Frame"],
							desc = L["Resets Main Frame position"],
							func = function()
								db.MinionLocation.Point = "CENTER"
								db.MinionLocation.RelativePoint =  "CENTER"
								db.MinionLocation.X = 0
								db.MinionLocation.Y = 0
								QuestTracker:MinionAnchorUpdate(true)
							end,
						},
						HeaderMiscSettingsSpacer = {
							name = "   ",
							width = "full",
							type = "description",
							order = 30,
						},
						HeaderMiscSettings = {
							name = L["Misc. Settings"],
							type = "header",
							order = 31,
						},
						ShowNumberQuestsToggle = {
							name = L["Show number of quests"],
							desc = L["Shows/Hides the number of quests"],
							type = "toggle",
							get = function() return db.ShowNumberOfQuests end,
							set = function()
								db.ShowNumberOfQuests = not db.ShowNumberOfQuests
								QuestTracker:UpdateMinion()
							end,
							order = 32,
						},
						ShowNumberOfDailyQuestsToggle = {
							name = L["Show # of Dailys"],
							desc = L["Shows/Hides the number of daily quests completed"],
							type = "toggle",
							get = function() return db.ShowNumberOfDailyQuests end,
							set = function()
								db.ShowNumberOfDailyQuests = not db.ShowNumberOfDailyQuests
								QuestTracker:UpdateMinion()
							end,
							order = 33,
						},
						ConfirmQuestAbandonsToggle = {
							name = L["Require confirmation when abandoning a Quest"],
							desc = L["Shows the confirm box when you try to abandon a quest"],
							type = "toggle",
							width = "full",
							get = function() return db.ConfirmQuestAbandons end,
							set = function()
								db.ConfirmQuestAbandons = not db.ConfirmQuestAbandons
								QuestTracker:UpdateMinion()
							end,
							order = 36,
						},	
						AutoTrackQuests = {
							name = L["Automatically track quests"],
							desc = L["Same as blizzard setting. Tracked quests are shown quests when the ability to hide quests is on."],
							width = "full",
							type = "toggle",
							get = function()
								if (GetCVar("autoQuestWatch") ==  "1") then
									return true
								else
									return false
								end
							end,
							set = function()
								if (GetCVar("autoQuestWatch") ==  "1") then
									SetCVar("autoQuestWatch", "0", AUTO_QUEST_WATCH_TEXT)
								else
									SetCVar("autoQuestWatch", "1", AUTO_QUEST_WATCH_TEXT)
								end
							end,
							order = 37,
						},
						AutoTrackQuestsWhenObjectiveupdate = {
							name = L["Automatically track quests when objectives update"],
							desc = L["Same as blizzard setting. Tracked quests are shown quests when the ability to hide quests is on."],
							width = "full",
							type = "toggle",
							get = function()
								if (GetCVar("autoQuestProgress") ==  "1") then
									return true
								else
									return false
								end
							end,
							set = function()
								if (GetCVar("autoQuestProgress") ==  "1") then
									SetCVar("autoQuestProgress", "0", AUTO_QUEST_PROGRESS_TEXT)
								else
									SetCVar("autoQuestProgress", "1", AUTO_QUEST_PROGRESS_TEXT)
								end
							end,
							order = 38,
						},
						OpenFullQuestLogToggle = {
							name = L["Left-click opens full Quest Log panel"],
							desc = L["Open the full quest log when clicking a quest.\nWhen disabled opens only the quest details panel for quests which are not completed remote quests.\n|cffffff78Alt-click always opens full log panel. |r"],
							width = "full",
							type = "toggle",
							get = function() return db.ZonesAndQuests.QuestClicksOpenFullQuestLog end,
							set = function()
								db.ZonesAndQuests.QuestClicksOpenFullQuestLog = not db.ZonesAndQuests.QuestClicksOpenFullQuestLog
							end,
							order = 42,
						},
					},						
				},
				Zones = {
					name = L["Zones"],
					type = "group",
					order = 2,
					args = {
						AllowHiddenQuestsToggle = {
							name = L["Allow quests to be hidden"],
							desc = L["Allows quests to be hidden and enables the show/hide button"],
							type = "toggle",
							width = "full",
							get = function() return db.ZonesAndQuests.AllowHiddenQuests end,
							set = function()
								db.ZonesAndQuests.AllowHiddenQuests = not db.ZonesAndQuests.AllowHiddenQuests
								QuestTracker:doHiddenQuestsUpdate()
								QuestTracker:UpdateMinion()
							end,
							order = 3,
						},
						AllowHiddenHeadersToggle = {
							name = L["Zone headers hide when all contained quests are hidden"],
							desc = L["Makes zone headers hide when all contained quests are hidden"],
							type = "toggle",
							disabled = function() return not db.ZonesAndQuests.AllowHiddenQuests end,
							width = "full",
							get = function() return db.ZonesAndQuests.QuestHeadersHideWhenEmpty end,
							set = function()
								db.ZonesAndQuests.QuestHeadersHideWhenEmpty = not db.ZonesAndQuests.QuestHeadersHideWhenEmpty
								QuestTracker:UpdateMinion()
							end,
							order = 4,
						},		
						AllowHiddenCountOnZonesToggle = {
							name = L["Display count of hidden quest in each zone"],
							desc = L["Displays a count of the hidden quests in each zone on the zone header"],
							type = "toggle",
							disabled = function() return not db.ZonesAndQuests.AllowHiddenQuests end,
							width = "full",
							get = function() return db.ZonesAndQuests.ShowHiddenCountOnZones end,
							set = function()
								db.ZonesAndQuests.ShowHiddenCountOnZones = not db.ZonesAndQuests.ShowHiddenCountOnZones
								QuestTracker:UpdateMinion()
							end,
							order = 5,
						},
						ExpandOnEnterToggle = {
							name = L["Auto expand zones on enter"],
							desc = L["Automatically expands zone headers when you enter the zone"],
							type = "toggle",
							get = function() return db.ZonesAndQuests.ExpandOnEnter end,
							set = function()
								db.ZonesAndQuests.ExpandOnEnter = not db.ZonesAndQuests.ExpandOnEnter
								QuestTracker:doHandleZoneChange()
							end,
							order = 22,
						},	
						CollapseOnLeaveToggle = {
							name = L["Auto collapse zones on exit"],
							desc = L["Automatically collapses zone headers when you exit the zone"],
							type = "toggle",
							get = function() return db.ZonesAndQuests.CollapseOnLeave end,
							set = function()
								db.ZonesAndQuests.CollapseOnLeave = not db.ZonesAndQuests.CollapseOnLeave
								QuestTracker:doHandleZoneChange()
							end,
							order = 23,
						},	
						HideZoneHeadersToggle = {
							name = L["Hide Zone Headers"],
							desc = L["Hides all zone headers and just displays quests. Note: Does not expand zone headers for you"],
							type = "toggle",
							get = function() return db.ZonesAndQuests.HideZoneHeaders end,
							set = function()
								db.ZonesAndQuests.HideZoneHeaders = not db.ZonesAndQuests.HideZoneHeaders
								QuestTracker:UpdateMinion()
							end,
							order = 28,
						},
						
					}
				},
				Quests = {
					name = L["Quests"],
					type = "group",
					order = 3,
					args = {
						ShowQuestLevelsToggle = {
							name = L["Display level in Quest Title"],
							desc = L["Displays the level of the quest in the title"],
							type = "toggle",
							width = "full",
							get = function() return db.ZonesAndQuests.ShowQuestLevels end,
							set = function()
								db.ZonesAndQuests.ShowQuestLevels = not db.ZonesAndQuests.ShowQuestLevels
								QuestTracker:UpdateMinion()
							end,
							order = 6,
						},
						QuestTagsLengthSelect = {
							name = L["Quest Tag Length:"],
							desc = L["The length of the quest tags (d, p, g5, ELITE etc)"],
							type = "select",
							order = 7,
							values = dicQuestTagsLength,
							get = function() return db.ZonesAndQuests.QuestTagsLength end,
							set = function(info, value)
								db.ZonesAndQuests.QuestTagsLength = value
								QuestTracker:UpdateMinion()
							end,
						},

						HeaderQuestsSpacer = {
							name = "   ",
							width = "full",
							type = "description",
							order = 40,
						},
						HeaderQuests = {
							name = L["Quest Settings"],
							type = "header",
							order = 41,
						},

						HideCompletedQuestsToggle = {
							name = L["Hide Completed quests/goto Quests"],
							desc = L["Automatically hides completed quests on completion. Also hides goto quests"],
							width = "full",
							type = "toggle",
							get = function() return db.ZonesAndQuests.HideCompletedQuests end,
							set = function()
								db.ZonesAndQuests.HideCompletedQuests = not db.ZonesAndQuests.HideCompletedQuests
								QuestTracker:UpdateMinion()
							end,
							order = 43,
						},
						QuestTitleIndent = {
							order = 48,
							name = L["Quest Text Indent"],
							desc = L["Controls the level of indentation for the quest text"],
							type = "range",
							min = 0, max = 20, step = 1,
							isPercent = false,
							get = function() return db.ZonesAndQuests.QuestTitleIndent end,
							set = function(info, value)
								db.ZonesAndQuests.QuestTitleIndent = value
								QuestTracker:UpdateMinion()
							end,
						},
						QuestAfterPadding = {
							order = 49,
							name = L["Padding After Quest"],
							desc = L["The amount of extra padding after a quest before the next text."],
							type = "range",
							min = 0, max = 20, step = 1,
							isPercent = false,
							get = function() return db.ZonesAndQuests.QuestAfterPadding end,
							set = function(info, value)
								db.ZonesAndQuests.QuestAfterPadding = value
								QuestTracker:UpdateMinion()
							end,
						},					
						
						HeaderObjectivesSpacer = {
							name = "   ",
							width = "full",
							type = "description",
							order = 80,
						},
						HeaderObjectives = {
							name = L["Objective Settings"],
							type = "header",
							order = 81,
						},
						HideCompletedObjectivesToggle = {
							name = L["Hide completed objectives"],
							desc = L["Shows/Hides completed objectives"],
							type = "toggle",
							width = "full",
							get = function() return db.ZonesAndQuests.HideCompletedObjectives end,
							set = function()
								db.ZonesAndQuests.HideCompletedObjectives = not db.ZonesAndQuests.HideCompletedObjectives
								QuestTracker:UpdateMinion()
							end,
							order = 82,
						},
						ShowDescWhenNoObjectivesToggle = {
							name = L["Display quest description if not objectives"],
							desc = L["Displays a quests description if there are no objectives available"],
							type = "toggle",
							width = "full",
							get = function() return db.ZonesAndQuests.ShowDescWhenNoObjectives end,
							set = function()
								db.ZonesAndQuests.ShowDescWhenNoObjectives = not db.ZonesAndQuests.ShowDescWhenNoObjectives
								QuestTracker:UpdateMinion()
							end,
							order = 83,
						},	
						ObjectivesIndent = {
									order = 88,
									name = L["Objective Text Indent"],
									desc = L["Controls the level of indentation for the Objective text"],
									type = "range",
									min = 0, max = 20, step = 1,
									isPercent = false,
									get = function() return db.ZonesAndQuests.ObjectivesIndent end,
									set = function(info, value)
										db.ZonesAndQuests.ObjectivesIndent = value
										QuestTracker:UpdateMinion()
									end,
								},					

					}
				},
				QuestItems = {
					name = L["Quest Items"],
					type = "group",
					order = 4,
					args = {
						HeaderItemButtons = {
							name = L["Item Button Settings"],
							type = "header",
							order = 71,
						},
						ShowItemButtonsToggle = {
							name = L["Show quest item buttons"],
							desc = L["Shows/Hides the quest item buttons"],
							type = "toggle",
							get = function() return db.ShowItemButtons end,
							set = function()
								db.ShowItemButtons = not db.ShowItemButtons
								QuestTracker:UpdateMinion()
							end,
							order = 72,
						},
						ItemsAndTooltipsRightToggle = {
							name = L["Display items and tooltips on right"],
							desc = L["Moves items and tooltips to the right"],
							type = "toggle",
							get = function() return db.MoveTooltipsRight end,
							set = function()
								db.MoveTooltipsRight = not db.MoveTooltipsRight
								QuestTracker:UpdateMinion()
							end,
							order = 73,
						},
						IndentItemButtonsToggle = {
							name = L["Indent item buttons inside tracker"],
							desc = L["Indents the item buttons into the quest tracker so they are flush with zone headers"],
							type = "toggle",
							width = "full",
							disabled = function() return (db.MoveTooltipsRight == true or db.ShowItemButtons == false) end,
							get = function() return db.IndentItemButtons end,
							set = function()
								db.IndentItemButtons = not db.IndentItemButtons
								QuestTracker:UpdateMinion()
							end,
							order = 74,
						},
						IndentItemButtonQuestsOnlyToggle = {
							name = L["Indent only quests with item buttons"],
							desc = L["Only indents a quest if the quest has an item button"],
							type = "toggle",
							width = "full",
							disabled = function() return (db.MoveTooltipsRight == true or db.IndentItemButtons == false or db.ShowItemButtons == false) end,
							get = function() return db.IndentItemButtonQuestsOnly end,
							set = function()
								db.IndentItemButtonQuestsOnly = not db.IndentItemButtonQuestsOnly
								QuestTracker:UpdateMinion()
							end,
							order = 75,
						},
						HideItemButtonsForCompletedQuestsToggle = {
							name = L["Hide Item Buttons for completed quests"],
							desc = L["Hides the quests item button once the quest is complete"],
							type = "toggle",
							width = "full",
							disabled = function() return not(db.ShowItemButtons) end,
							get = function() return db.HideItemButtonsForCompletedQuests end,
							set = function()
								db.HideItemButtonsForCompletedQuests = not db.HideItemButtonsForCompletedQuests
								QuestTracker:UpdateMinion()
							end,
							order = 76,
						},						
						ItemButtonsSizeSlider = {
							order = 77,
							name = L["Item Button Size"],
							desc = L["Controls the size of the Item Buttons."],
							type = "range",
							disabled = function() return not(db.ShowItemButtons) end,
							min = 0.5, max = 2, step = 0.05,
							isPercent = false,
							get = function() return db.ItemButtonScale end,
							set = function(info, value)
								db.ItemButtonScale = value
								QuestTracker:UpdateMinion()
							end,
						},											
					}
				},
				Fonts = {
					name = L["Fonts"],
					type = "group",
					order = 5,
					args = {
						HeaderTitleFont = {
							name = L["Info Text Font Settings"],
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
								QuestTracker:UpdateMinion()
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
								QuestTracker:UpdateMinion()
							end,
						},
						MinionTitleFontShadowedToggle = {
							name = L["Shadow Text"],
							desc = L["Shows/Hides text shadowing"],
							type = "toggle",
							get = function() return db.Fonts.MinionTitleFontShadowed end,
							set = function()
								db.Fonts.MinionTitleFontShadowed = not db.Fonts.MinionTitleFontShadowed
								QuestTracker:UpdateMinion()
							end,
							order = 44,
						},
						MinionTitleFontSizeSelect = {
							order = 45,
							name = L["Font Size"],
							desc = L["Controls the font size this font"],
							type = "range",
							min = 8, max = 20, step = 1,
							isPercent = false,
							get = function() return db.Fonts.MinionTitleFontSize end,
							set = function(info, value)
								db.Fonts.MinionTitleFontSize = value
								QuestTracker:UpdateMinion()
							end,
						},
						MinionTitleFontLineSpacing = {
							order = 46,
							name = L["Font Line Spacing"],
							desc = L["Controls the spacing below each line of this font"],
							type = "range",
							min = 0, max = 20, step = 1,
							isPercent = false,
							get = function() return db.Fonts.MinionTitleFontLineSpacing end,
							set = function(info, value)
								db.Fonts.MinionTitleFontLineSpacing = value
								QuestTracker:UpdateMinion()
							end,
						},

						ZonesFontSpacer = {
							name = "   ",
							width = "full",
							type = "description",
							order = 50,
						},
						ZonesFontHeader = {
							name = L["Zone Font Settings"],
							type = "header",
							order = 51,
						},
						ZonesFontSelect = {
							type = "select", dialogControl = 'LSM30_Font',
							order = 52,
							name = L["Font"],
							desc = L["The font used for this element"],
							values = AceGUIWidgetLSMlists.font,
							get = function() return db.Fonts.HeaderFont end,
							set = function(info, value)
								db.Fonts.HeaderFont = value
								QuestTracker:UpdateMinion()
							end,
						},
						ZonesFontOutlineSelect = {
							name = L["Font Outline"],
							desc = L["The outline that this font will use"],
							type = "select",
							order = 53,
							values = dicOutlines,
							get = function() return db.Fonts.HeaderFontOutline end,
							set = function(info, value)
								db.Fonts.HeaderFontOutline = value
								QuestTracker:UpdateMinion()
							end,
						},
						ZonesFontShadowedToggle = {
							name = L["Shadow Text"],
							desc = L["Shows/Hides text shadowing"],
							type = "toggle",
							get = function() return db.Fonts.HeaderFontShadowed end,
							set = function()
								db.Fonts.HeaderFontShadowed = not db.Fonts.HeaderFontShadowed
								QuestTracker:UpdateMinion()
							end,
							order = 54,
						},
						ZonesFontSize = {
							order = 55,
							name = L["Font Size"],
							desc = L["Controls the font size this font"],
							type = "range",
							min = 8, max = 20, step = 1,
							isPercent = false,
							get = function() return db.Fonts.HeaderFontSize end,
							set = function(info, value)
								db.Fonts.HeaderFontSize = value
								QuestTracker:UpdateMinion()
							end,
						},
						ZonesFontLineSpacing = {
							order = 56,
							name = L["Font Line Spacing"],
							desc = L["Controls the spacing below each line of this font"],
							type = "range",
							min = 0, max = 20, step = 1,
							isPercent = false,
							get = function() return db.Fonts.HeaderFontLineSpacing end,
							set = function(info, value)
								db.Fonts.HeaderFontLineSpacing = value
								QuestTracker:UpdateMinion()
							end,
						},
						
						
						QuestFontSpacer = {
							name = "   ",
							width = "full",
							type = "description",
							order = 60,
						},
						QuestFontHeader = {
							name = L["Quest Font Settings"],
							type = "header",
							order = 61,
						},
						QuestFontSelect = {
							type = "select", dialogControl = 'LSM30_Font',
							order = 62,
							name = L["Font"],
							desc = L["The font used for this element"],
							values = AceGUIWidgetLSMlists.font,
							get = function() return db.Fonts.QuestFont end,
							set = function(info, value)
								db.Fonts.QuestFont = value
								QuestTracker:UpdateMinion()
							end,
						},
						QuestFontOutlineSelect = {
							name = L["Font Outline"],
							desc = L["The outline that this font will use"],
							type = "select",
							order = 63,
							values = dicOutlines,
							get = function() return db.Fonts.QuestFontOutline end,
							set = function(info, value)
								db.Fonts.QuestFontOutline = value
								QuestTracker:UpdateMinion()
							end,
						},
						QuestFontShadowedToggle = {
							name = L["Shadow Text"],
							desc = L["Shows/Hides text shadowing"],
							type = "toggle",
							get = function() return db.Fonts.QuestFontShadowed end,
							set = function()
								db.Fonts.QuestFontShadowed = not db.Fonts.QuestFontShadowed
								QuestTracker:UpdateMinion()
							end,
							order = 64,
						},
						QuestFontSize = {
							order = 65,
							name = L["Font Size"],
							desc = L["Controls the font size this font"],
							type = "range",
							min = 8, max = 20, step = 1,
							isPercent = false,
							get = function() return db.Fonts.QuestFontSize end,
							set = function(info, value)
								db.Fonts.QuestFontSize = value
								QuestTracker:UpdateMinion()
							end,
						},
						QuestFontLineSpacing = {
							order = 66,
							name = L["Font Line Spacing"],
							desc = L["Controls the spacing below each line of this font"],
							type = "range",
							min = 0, max = 20, step = 1,
							isPercent = false,
							get = function() return db.Fonts.QuestFontLineSpacing end,
							set = function(info, value)
								db.Fonts.QuestFontLineSpacing = value
								QuestTracker:UpdateMinion()
							end,
						},
						
						ObjectiveFontSpacer = {
							name = "   ",
							width = "full",
							type = "description",
							order = 70,
						},
						ObjectiveFontHeader = {
							name = L["Objective Font Settings"],
							type = "header",
							order = 71,
						},
						ObjectiveFontSelect = {
							type = "select", dialogControl = 'LSM30_Font',
							order = 72,
							name = L["Font"],
							desc = L["The font used for this element"],
							values = AceGUIWidgetLSMlists.font,
							get = function() return db.Fonts.ObjectiveFont end,
							set = function(info, value)
								db.Fonts.ObjectiveFont = value
								QuestTracker:UpdateMinion()
							end,
						},
						ObjectiveFontOutlineSelect = {
							name = L["Font Outline"],
							desc = L["The outline that this font will use"],
							type = "select",
							order = 73,
							values = dicOutlines,
							get = function() return db.Fonts.ObjectiveFontOutline end,
							set = function(info, value)
								db.Fonts.ObjectiveFontOutline = value
								QuestTracker:UpdateMinion()
							end,
						},
						ObjectiveFontShadowedToggle = {
							name = L["Shadow Text"],
							desc = L["Shows/Hides text shadowing"],
							type = "toggle",
							get = function() return db.Fonts.ObjectiveFontShadowed end,
							set = function()
								db.Fonts.ObjectiveFontShadowed = not db.Fonts.ObjectiveFontShadowed
								QuestTracker:UpdateMinion()
							end,
							order = 74,
						},	
						ObjectiveFontSize = {
							order = 75,
							name = L["Font Size"],
							desc = L["Controls the font size this font"],
							type = "range",
							min = 8, max = 20, step = 1,
							isPercent = false,
							get = function() return db.Fonts.ObjectiveFontSize end,
							set = function(info, value)
								db.Fonts.ObjectiveFontSize = value
								QuestTracker:UpdateMinion()
							end,
						},
						ObjectiveFontLineSpacing = {
							order = 76,
							name = L["Font Line Spacing"],
							desc = L["Controls the spacing below each line of this font"],
							type = "range",
							min = 0, max = 20, step = 1,
							isPercent = false,
							get = function() return db.Fonts.ObjectiveFontLineSpacing end,
							set = function(info, value)
								db.Fonts.ObjectiveFontLineSpacing = value
								QuestTracker:UpdateMinion()
							end,
						},
					}
				},
				Colours = {
					name = L["Colours"],
					type = "group",
					order = 6,
					args = {
						InfoTextColour = {
							name = L["Info Text"],
							desc = L["Sets the color of the info text (Title bar, # of quests hidden etc)"],
							type = "color",
							hasAlpha = true,
							get = function() return db.Colours.InfoColour.r, db.Colours.InfoColour.g, db.Colours.InfoColour.b, db.Colours.InfoColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.InfoColour.r = r
									db.Colours.InfoColour.g = g
									db.Colours.InfoColour.b = b
									db.Colours.InfoColour.a = a
									QuestTracker:HandleColourChanges()
								end,
							order = 2,
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
									QuestTracker:HandleColourChanges()
								end,
							order = 4,
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
									QuestTracker:HandleColourChanges()
								end,
							order = 5,
						},
						HeaderColourSettings = {
							name = L["Colour Settings"],
							type = "header",
							order = 10,
						},
						QuestLevelColouringSelect = {
							name = L["Colour quest levels by:"],
							desc = L["The setting by which the colour of quest levels are determined"],
							type = "select",
							order = 11,
							values = dicQuestTitleColourOptions,
							get = function() return db.ZonesAndQuests.QuestLevelColouringSetting end,
							set = function(info, value)
								db.ZonesAndQuests.QuestLevelColouringSetting = value
								QuestTracker:UpdateMinion()
							end,
						},
						QuestTitleColouringSelect = {
							name = L["Colour quest titles by:"],
							desc = L["The setting by which the colour of quest titles is determined"],
							type = "select",
							order = 12,
							values = dicQuestTitleColourOptions,
							get = function() return db.ZonesAndQuests.QuestTitleColouringSetting end,
							set = function(info, value)
								db.ZonesAndQuests.QuestTitleColouringSetting = value
								QuestTracker:UpdateMinion()
							end,
						},
						ObjectiveTitleColouringSelect = {
							name = L["Colour objective title text by:"],
							desc = L["The setting by which the colour of objective title is determined"],
							type = "select",
							order = 13,
							values = dicObjectiveColourOptions,
							get = function() return db.ZonesAndQuests.ObjectiveTitleColouringSetting end,
							set = function(info, value)
								db.ZonesAndQuests.ObjectiveTitleColouringSetting = value
								QuestTracker:UpdateMinion()
							end,
						},
						ObjectiveStatusColouringSelect = {
							name = L["Colour objective status text by:"],
							desc = L["The setting by which the colour of objective statuses is determined"],
							type = "select",
							order = 14,
							values = dicObjectiveColourOptions,
							get = function() return db.ZonesAndQuests.ObjectiveStatusColouringSetting end,
							set = function(info, value)
								db.ZonesAndQuests.ObjectiveStatusColouringSetting = value
								QuestTracker:UpdateMinion()
							end,
						},
						HeaderMainColoursSpacer = {
							name = "   ",
							width = "full",
							type = "description",
							order = 20,
						},
						HeaderMainColours = {
							name = L["Main Colours"],
							type = "header",
							order = 21,
						},
						HeaderColour = {
							name = L["Zone Header Colour"],
							desc = L["Sets the color for the header of each zone"],
							type = "color",
							hasAlpha = true,
							get = function() return db.Colours.HeaderColour.r, db.Colours.HeaderColour.g, db.Colours.HeaderColour.b, db.Colours.HeaderColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.HeaderColour.r = r
									db.Colours.HeaderColour.g = g
									db.Colours.HeaderColour.b = b
									db.Colours.HeaderColour.a = a
									QuestTracker:HandleColourChanges()
								end,
							order = 24,
						},
						QuestLevelColour = {
							name = L["Quest levels"],
							desc = L["Sets the color for the quest levels if custom colouring is on"],
							type = "color",
							disabled = function() return not(db.ZonesAndQuests.QuestLevelColouringSetting == "Custom") end,
							hasAlpha = true,
							get = function() return db.Colours.QuestLevelColour.r, db.Colours.QuestLevelColour.g, db.Colours.QuestLevelColour.b, db.Colours.QuestLevelColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.QuestLevelColour.r = r
									db.Colours.QuestLevelColour.g = g
									db.Colours.QuestLevelColour.b = b
									db.Colours.QuestLevelColour.a = a
									QuestTracker:HandleColourChanges()
								end,
							order = 25,
						},
						QuestTitleColour = {
							name = L["Quest titles"],
							desc = L["Sets the color for the quest titles if colouring by level is off"],
							type = "color",
							disabled = function() return not(db.ZonesAndQuests.QuestTitleColouringSetting == "Custom") end,
							hasAlpha = true,
							get = function() return db.Colours.QuestTitleColour.r, db.Colours.QuestTitleColour.g, db.Colours.QuestTitleColour.b, db.Colours.QuestTitleColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.QuestTitleColour.r = r
									db.Colours.QuestTitleColour.g = g
									db.Colours.QuestTitleColour.b = b
									db.Colours.QuestTitleColour.a = a
									QuestTracker:HandleColourChanges()
								end,
							order = 26,
						},
						NoObjectivesColour = {
							name = L["No objectives description colour"],
							desc = L["Sets the color for the description displayed when there is no quest objectives"],
							type = "color",
							hasAlpha = true,
							get = function() return db.Colours.ObjectiveDescColour.r, db.Colours.ObjectiveDescColour.g, db.Colours.ObjectiveDescColour.b, db.Colours.ObjectiveDescColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.ObjectiveDescColour.r = r
									db.Colours.ObjectiveDescColour.g = g
									db.Colours.ObjectiveDescColour.b = b
									db.Colours.ObjectiveDescColour.a = a
									QuestTracker:HandleColourChanges()
								end,
							order = 27,
						},
						ObjectiveTitleColourPicker = {
							name = L["Objective title colour"],
							desc = L["Sets the custom color for objectives titles"],
							type = "color",
							disabled = function() return not(db.ZonesAndQuests.ObjectiveTitleColouringSetting == "Custom") end,
							hasAlpha = true,
							get = function() return db.Colours.ObjectiveTitleColour.r, db.Colours.ObjectiveTitleColour.g, db.Colours.ObjectiveTitleColour.b, db.Colours.ObjectiveTitleColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.ObjectiveTitleColour.r = r
									db.Colours.ObjectiveTitleColour.g = g
									db.Colours.ObjectiveTitleColour.b = b
									db.Colours.ObjectiveTitleColour.a = a
									QuestTracker:HandleColourChanges()
								end,
							order = 28,
						},
						ObjectiveStatusColourPicker = {
							name = L["Objective status colour"],
							desc = L["Sets the custom color for objectives statuses"],
							type = "color",
							disabled = function() return not(db.ZonesAndQuests.ObjectiveStatusColouringSetting == "Custom") end,
							hasAlpha = true,
							get = function() return db.Colours.ObjectiveStatusColour.r, db.Colours.ObjectiveStatusColour.g, db.Colours.ObjectiveStatusColour.b, db.Colours.ObjectiveStatusColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.ObjectiveStatusColour.r = r
									db.Colours.ObjectiveStatusColour.g = g
									db.Colours.ObjectiveStatusColour.b = b
									db.Colours.ObjectiveStatusColour.a = a
									QuestTracker:HandleColourChanges()
								end,
							order = 29,
						},
						QuestStatusFailedColourPicker = {
							name = L["Quest failed tag"],
							desc = L["Sets the color for the quest failed tag"],
							type = "color",
							hasAlpha = true,
							get = function() return db.Colours.QuestStatusFailedColour.r, db.Colours.QuestStatusFailedColour.g, db.Colours.QuestStatusFailedColour.b, db.Colours.QuestStatusFailedColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.QuestStatusFailedColour.r = r
									db.Colours.QuestStatusFailedColour.g = g
									db.Colours.QuestStatusFailedColour.b = b
									db.Colours.QuestStatusFailedColour.a = a
									QuestTracker:HandleColourChanges()
								end,
							order = 30,
						},								
						QuestStatusDoneColourPicker = {
							name = L["Quest done tag"],
							desc = L["Sets the color for the quest done tag"],
							type = "color",
							hasAlpha = true,
							get = function() return db.Colours.QuestStatusDoneColour.r, db.Colours.QuestStatusDoneColour.g, db.Colours.QuestStatusDoneColour.b, db.Colours.QuestStatusDoneColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.QuestStatusDoneColour.r = r
									db.Colours.QuestStatusDoneColour.g = g
									db.Colours.QuestStatusDoneColour.b = b
									db.Colours.QuestStatusDoneColour.a = a
									QuestTracker:HandleColourChanges()
								end,
							order = 31,
						},									
						QuestStatusGotoColourPicker = {
							name = L["Quest goto Tag"],
							desc = L["Sets the color for the quest goto tag"],
							type = "color",
							hasAlpha = true,
							get = function() return db.Colours.QuestStatusGotoColour.r, db.Colours.QuestStatusGotoColour.g, db.Colours.QuestStatusGotoColour.b, db.Colours.QuestStatusGotoColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.QuestStatusGotoColour.r = r
									db.Colours.QuestStatusGotoColour.g = g
									db.Colours.QuestStatusGotoColour.b = b
									db.Colours.QuestStatusGotoColour.a = a
									QuestTracker:HandleColourChanges()
								end,
							order = 32,
						},		
						ObjectiveTooltipTextColourColourPicker = {
							name = L["Objective Tooltip Text"],
							desc = L["Sets the color for the objective text in the quests tooltip"],
							type = "color",
							hasAlpha = true,
							get = function() return db.Colours.ObjectiveTooltipTextColour.r, db.Colours.ObjectiveTooltipTextColour.g, db.Colours.ObjectiveTooltipTextColour.b, db.Colours.ObjectiveTooltipTextColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.ObjectiveTooltipTextColour.r = r
									db.Colours.ObjectiveTooltipTextColour.g = g
									db.Colours.ObjectiveTooltipTextColour.b = b
									db.Colours.ObjectiveTooltipTextColour.a = a
									QuestTracker:HandleColourChanges()
								end,
							order = 33,
						},		
						HeaderGradualColoursSpacer = {
							name = "   ",
							width = "full",
							type = "description",
							order = 50,
						},
						HeaderGradualColours = {
							name = L["Gradual objective Colours"],
							type = "header",
							order = 51,
						},
						Objective00PlusColour = {
							name = L["0% Complete objective colour"],
							desc = L["Sets the color for objectives that are above 0% complete"],
							type = "color",
							hasAlpha = true,
							get = function() return db.Colours.Objective00PlusColour.r, db.Colours.Objective00PlusColour.g, db.Colours.Objective00PlusColour.b, db.Colours.Objective00PlusColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.Objective00PlusColour.r = r
									db.Colours.Objective00PlusColour.g = g
									db.Colours.Objective00PlusColour.b = b
									db.Colours.Objective00PlusColour.a = a
									QuestTracker:HandleColourChanges()
								end,
							order = 52,
						},
						Objective25PlusColour = {
							name = L["25% Complete objective colour"],
							desc = L["Sets the color for objectives that are above 25% complete"],
							type = "color",
							disabled = function() return not(db.ZonesAndQuests.ObjectiveTitleColouringSetting == "Completion" or db.ZonesAndQuests.ObjectiveStatusColouringSetting == "Completion" or db.ZonesAndQuests.QuestLevelColouringSetting == "Completion" or db.ZonesAndQuests.QuestTitleColouringSetting == "Completion") end,
							hasAlpha = true,
							get = function() return db.Colours.Objective25PlusColour.r, db.Colours.Objective25PlusColour.g, db.Colours.Objective25PlusColour.b, db.Colours.Objective25PlusColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.Objective25PlusColour.r = r
									db.Colours.Objective25PlusColour.g = g
									db.Colours.Objective25PlusColour.b = b
									db.Colours.Objective25PlusColour.a = a
									QuestTracker:HandleColourChanges()
								end,
							order = 53,
						},
						Objective50PlusColour = {
							name = L["50% Complete objective colour"],
							desc = L["Sets the color for objectives that are above 50% complete"],
							type = "color",
							disabled = function() return not(db.ZonesAndQuests.ObjectiveTitleColouringSetting == "Completion" or db.ZonesAndQuests.ObjectiveStatusColouringSetting == "Completion" or db.ZonesAndQuests.QuestLevelColouringSetting == "Completion" or db.ZonesAndQuests.QuestTitleColouringSetting == "Completion") end,
							hasAlpha = false,
							get = function() return db.Colours.Objective50PlusColour.r, db.Colours.Objective50PlusColour.g, db.Colours.Objective50PlusColour.b, db.Colours.Objective50PlusColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.Objective50PlusColour.r = r
									db.Colours.Objective50PlusColour.g = g
									db.Colours.Objective50PlusColour.b = b
									db.Colours.Objective50PlusColour.a = a
									QuestTracker:HandleColourChanges()
								end,
							order = 54,
						},
						Objective75PlusColour = {
							name = L["75% Complete objective colour"],
							desc = L["Sets the color for objectives that are above 75% complete"],
							type = "color",
							disabled = function() return not(db.ZonesAndQuests.ObjectiveTitleColouringSetting == "Completion" or db.ZonesAndQuests.ObjectiveStatusColouringSetting == "Completion" or db.ZonesAndQuests.QuestLevelColouringSetting == "Completion" or db.ZonesAndQuests.QuestTitleColouringSetting == "Completion") end,
							hasAlpha = true,
							get = function() return db.Colours.Objective75PlusColour.r, db.Colours.Objective75PlusColour.g, db.Colours.Objective75PlusColour.b, db.Colours.Objective75PlusColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.Objective75PlusColour.r = r
									db.Colours.Objective75PlusColour.g = g
									db.Colours.Objective75PlusColour.b = b
									db.Colours.Objective75PlusColour.a = a
									QuestTracker:HandleColourChanges()
								end,
							order = 55,
						},
						DoneObjectiveColour = {
							name = L["Complete objective colour"],
							desc = L["Sets the color for the complete objectives"],
							type = "color",
							hasAlpha = true,
							get = function() return db.Colours.ObjectiveDoneColour.r, db.Colours.ObjectiveDoneColour.g, db.Colours.ObjectiveDoneColour.b, db.Colours.ObjectiveDoneColour.a end,
							set = function(_,r,g,b,a)
									db.Colours.ObjectiveDoneColour.r = r
									db.Colours.ObjectiveDoneColour.g = g
									db.Colours.ObjectiveDoneColour.b = b
									db.Colours.ObjectiveDoneColour.a = a
									QuestTracker:HandleColourChanges()
								end,
							order = 56,
						},

					}
				},
				Notifications = {
					name = L["Notifications"],
					type = "group",
					childGroups = "tab",
					order = 7,
					args = {
						Notifications2 = {
							name = L["Notifications"],
							type = "group",
							order = 7,
							args = {
								NotificationSettingsHeader = {
									name = L["Text Notification Settings"],
									type = "header",
									order = 1,
								},
								SuppressBlizzardNotificationsToggle = {
									name = L["Suppress blizzard notification messages"],
									desc = L["Suppresses the notification messages sent by blizzard to the UIErrors Frame for progress updates"],
									type = "toggle",
									width = "full",
									get = function() return db.Notifications.SuppressBlizzardNotifications end,
									set = function()
										db.Notifications.SuppressBlizzardNotifications = not db.Notifications.SuppressBlizzardNotifications
									end,
									order = 2,
								},
								LibSinkHeaderSpacer = {
									name = "   ",
									width = "full",
									type = "description",
									order = 20,
								},
								LibSinkHeader = {
									name = L["LibSink Options"],
									type = "header",
									order = 21,
								},
								LibSinkObjectivesSmallHeader = {
									name = "|cff00ff00" .. L["Objective Notifications"] .. "|r",
									width = "full",
									type = "description",
									order = 22,
								},
								LibSinkObjectiveNotificationsToggle = {
									name = L["Use for Objective notification messages"],
									desc = L["Displays objective notification messages using LibSink"],
									type = "toggle",
									get = function() return db.Notifications.LibSinkObjectiveNotifications end,
									set = function()
										db.Notifications.LibSinkObjectiveNotifications = not db.Notifications.LibSinkObjectiveNotifications
									end,
									order = 23,
								},
								DisplayQuestOnObjectiveNotificationsToggle = {
									name = L["Display Quest Name"],
									desc = L["Adds the quest name to objective notification messages"],
									type = "toggle",
									disabled = function() return not(db.Notifications.LibSinkObjectiveNotifications) end,
									get = function() return db.Notifications.DisplayQuestOnObjectiveNotifications end,
									set = function()
										db.Notifications.DisplayQuestOnObjectiveNotifications = not db.Notifications.DisplayQuestOnObjectiveNotifications
									end,
									order = 24,
								},
								LibSinkQuestsSmallHeader = {
									name = "|cff00ff00" .. L["Quest Notifications"] .. "|r",
									width = "full",
									type = "description",
									order = 26,
								},
								ShowQuestCompletesAndFailsToggle = {
									name = L["Output Complete and Failed messages for quests"],
									desc = L["Displays '<Quest Title> (Complete)' etc messages once you finish all objectives"],
									type = "toggle",
									width = "full",
									get = function() return db.Notifications.ShowQuestCompletesAndFails end,
									set = function()
										db.Notifications.ShowQuestCompletesAndFails = not db.Notifications.ShowQuestCompletesAndFails
									end,
									order = 27,
								},
								ShowMessageOnPickingUpQuestItemToggle = {
									name = L["Show message when picking up an item that starts a quest"],
									desc = L["Displays a message through LibSink when you pick up an item that starts a quest"],
									type = "toggle",
									width = "full",
									get = function() return db.Notifications.ShowMessageOnPickingUpQuestItem end,
									set = function()
										db.Notifications.ShowMessageOnPickingUpQuestItem = not db.Notifications.ShowMessageOnPickingUpQuestItem
									end,
									order = 28,
								},
								LibSinkColourSmallHeaderSpacer = {
									name = "   ",
									width = "full",
									type = "description",
									order = 29,
								},
								LibSinkColourSmallHeader = {
									name = "|cff00ff00" .. L["Colour Settings"] .. "|r",
									width = "full",
									type = "description",
									order = 30,
								},
								NotificationsColourSelect = {
									name = L["Lib Sink Colour by:"],
									desc = L["The setting by which the colour of notification messages are determined"],
									type = "select",
									order = 31,
									values = dicNotificationColourOptions,
									get = function() return db.Notifications.LibSinkColourSetting end,
									set = function(info, value)
										db.Notifications.LibSinkColourSetting = value
									end,
								},
								NotificationsColour = {
									name = L["Notifications"],
									desc = L["Sets the color for notifications"],
									type = "color",
									hasAlpha = true,
									get = function() return db.Colours.NotificationsColour.r, db.Colours.NotificationsColour.g, db.Colours.NotificationsColour.b, db.Colours.NotificationsColour.a end,
									set = function(_,r,g,b,a)
											db.Colours.NotificationsColour.r = r
											db.Colours.NotificationsColour.g = g
											db.Colours.NotificationsColour.b = b
											db.Colours.NotificationsColour.a = a
										end,
									order = 32,
								},
								SoundSettingsHeaderSpacer = {
									name = "   ",
									width = "full",
									type = "description",
									order = 80,
								},
								SoundSettingsHeader = {
									name = L["Sound Settings"],
									type = "header",
									order = 81,
								},
								ObjectiveDoneSoundSelect = {
									name = L["Objective Completion Sound"], 
									desc = L["The sound played when you complete a quests objective"],
									type = "select", 
									dialogControl = "LSM30_Sound", 
									values = AceGUIWidgetLSMlists.sound, 
									get = function() return db.Notifications.ObjectiveDoneSound end,
									set = function(info, value)
										db.Notifications.ObjectiveDoneSound = value
									end,
									order = 82
								},
								QuestDoneSoundSelect = {
									name = L["Quest Completion Sound"], 
									desc = L["The sound played when you complete a quest (Finish all objectives)"],
									type = "select", 
									dialogControl = "LSM30_Sound", 
									values = AceGUIWidgetLSMlists.sound, 
									get = function() return db.Notifications.QuestDoneSound end,
									set = function(info, value)
										db.Notifications.QuestDoneSound = value
									end,
									order = 83
								},
								QuestItemFoundSoundSelect = {
									name = L["Quest Starting Item Picked Up"], 
									desc = L["The sound played when you pickup an item that starts a quest"],
									type = "select", 
									dialogControl = "LSM30_Sound", 
									values = AceGUIWidgetLSMlists.sound, 
									get = function() return db.Notifications.QuestItemFoundSound end,
									set = function(info, value)
										db.Notifications.QuestItemFoundSound = value
									end,
									order = 84
								},
							}
						},
						NotificationsOptions = QuestTracker:GetSinkAce3OptionsDataTable(),
					}
				},
			}
		}
	end

	return options
end

--Inits
function QuestTracker:OnInitialize()
	self.db = SorhaQuestLog.db:RegisterNamespace(MODNAME, defaults)
	db = self.db.profile
	dbChar = self.db.char	
	dbCore = SorhaQuestLog.db.profile
	self:SetSinkStorage(db)
	
	self:SetEnabledState(SorhaQuestLog:GetModuleEnabled(MODNAME))
	SorhaQuestLog:RegisterModuleOptions(MODNAME, getOptions, L["Quest Tracker"])
	
	self:UpdateColourStrings()
	self:MinionAnchorUpdate(true)
end

function QuestTracker:OnEnable()
	strZone = GetRealZoneText()
	strSubZone = GetSubZoneText()
	self:RegisterEvent("QUEST_LOG_UPDATE")	
	self:RegisterEvent('PLAYER_LEVEL_UP');
	self:RegisterEvent("ZONE_CHANGED")
	self:RegisterEvent("ZONE_CHANGED_INDOORS")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	
	
	-- Hook for moving quest progress messages
	self:RawHookScript(UIErrorsFrame, "OnEvent", function(self, event, msg, ...) 
		QuestTracker:HandleUIErrorsFrame(self, event, msg, ...) 
	end)
	
	-- Hook for firing an update when user tracks/untracks a quest in blizzard QL
	self:SecureHook("QuestLogTitleButton_OnClick", function(self, button)
		if (IsModifiedClick("QUESTWATCHTOGGLE")) then
			if (blnMinionUpdating == false) then
				QuestTracker:UpdateMinion()
			end
		end
	end);	
	
	intTimeSinceLastSound = GetTime()
	self:MinionAnchorUpdate(false)
	self:UpdateMinion()
end

function QuestTracker:OnDisable()
	self:UnregisterEvent("QUEST_LOG_UPDATE")	
	self:UnregisterEvent('PLAYER_LEVEL_UP');
	self:UnregisterEvent("ZONE_CHANGED")
	self:UnregisterEvent("ZONE_CHANGED_INDOORS")
	self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
	self:UpdateMinion()
end

function QuestTracker:Refresh()
	db = self.db.profile
	dbCore = SorhaQuestLog.db.profile
	self:SetSinkStorage(db)
	
	self:HandleColourChanges()
	self:doHiddenQuestsUpdate()
	self:MinionAnchorUpdate(true)	
end

--Events/handlers
function QuestTracker:QUEST_LOG_UPDATE(...)
	if (blnHaveRegisteredBagUpdate == false) then
		blnHaveRegisteredBagUpdate = true
		self:RegisterEvent("BAG_UPDATE")
	end
	
	if (blnHaveRefreshedHeaders == false) then
		blnHaveRefreshedHeaders = true
		self:RefreshZoneHeadersState()
	end	

	if (blnWasAClick == true) then -- Was the event called from a click (Skips the delay on header collapses etc)
		blnMinionUpdating = true
		self:UpdateMinion()
	elseif (blnMinionUpdating == false) then --If not updating then update, forces a 0.5 second delay between system called updates
		if (blnIgnoreUpdateEvents == false) then
			blnMinionUpdating = true
			self:ScheduleTimer("UpdateMinion", 0.3)
		end
	end
end

function QuestTracker:PLAYER_LEVEL_UP(...)
	if (blnMinionUpdating == false) then 
		blnMinionUpdating = true
		self:ScheduleTimer("UpdateMinion", 0.3)
	end
end

function QuestTracker:ZONE_CHANGED(...)
	self:doHandleZoneChange()
end

function QuestTracker:ZONE_CHANGED_INDOORS(...)
	self:doHandleZoneChange()
end

function QuestTracker:ZONE_CHANGED_NEW_AREA(...)
	if (strZone == nil) then 
		strZone = GetRealZoneText()
		strSubZone = GetSubZoneText()
	end
	self:doHandleZoneChange()
end

function QuestTracker:BAG_UPDATE(...)
	local intBag = select(2,...)
	
	if (db.Notifications.ShowMessageOnPickingUpQuestItem == true) then
		if (intBag < 5) then
			if (tContains(tblBagsToCheck, intBag) == nil) then
				tinsert(tblBagsToCheck, intBag)
			end
			if (blnBagCheckUpdating == false) then
				blnBagCheckUpdating = true
				self:ScheduleTimer("CheckBags", 1)
			end
		end
	end
end

function QuestTracker:HandleUIErrorsFrame(frame, event, msg, ...)
	if (event == "UI_INFO_MESSAGE") then
		for k, strPattern in pairs(tblQuestMatchs) do
			if (msg:match(strPattern)) then
				if (db.Notifications.SuppressBlizzardNotifications == true) then
					return
				end
				break
			end
		end
	end
	QuestTracker.hooks[frame].OnEvent(frame, event, msg, ...)
end

--Buttons
function QuestTracker:GetMinionButton()
	local objButton = SorhaQuestLog:GetLogButton()
	objButton:SetParent(fraMinionAnchor)
	
	-- Create scripts
	objButton:RegisterForClicks("AnyUp")
	objButton:SetScript("OnClick", function(self, button)
		blnWasAClick = true

		if (button == "LeftButton") then
			if (self.isHeader == 1) then
				if (self.isCollapsed == 1) then
					ExpandQuestHeader(self.LogPosition)
				else
					CollapseQuestHeader(self.LogPosition)
				end
			else
				if (IsShiftKeyDown()) then -- Chat Link Quest/Show or Hide Track
					if ChatEdit_GetActiveWindow() then -- Link in chat
						ChatEdit_InsertLink(GetQuestLink(self.LogPosition))
					else -- Track/untrack quest
						if (db.ZonesAndQuests.AllowHiddenQuests == true) then
							if (IsQuestWatched(self.LogPosition) == nil) then
								if (GetNumQuestWatches() >= 25) then
									UIErrorsFrame:AddMessage(format(QUEST_WATCH_TOO_MANY, 25), 1.0, 0.1, 0.1, 1.0);
								else
									AddQuestWatch(self.LogPosition)
								end
							else
								RemoveQuestWatch(self.LogPosition)
							end
							QuestTracker:UpdateMinion()
						end
					end
									
				elseif (IsControlKeyDown() and IsAltKeyDown()) then -- Abandon Quest
					local intCurrentSelectedIndex = GetQuestLogSelection()
					SelectQuestLogEntry(self.LogPosition)
					SetAbandonQuest()
					if ( QuestLogDetailFrame:IsShown() ) then
						HideUIPanel(QuestLogDetailFrame);
					end
					
					if (db.ConfirmQuestAbandons == true) then
						local items = GetAbandonQuestItems();
						if ( items ) then
							StaticPopup_Hide("ABANDON_QUEST");
							StaticPopup_Show("ABANDON_QUEST_WITH_ITEMS", GetAbandonQuestName(), items);
						else
							StaticPopup_Hide("ABANDON_QUEST_WITH_ITEMS");
							StaticPopup_Show("ABANDON_QUEST", GetAbandonQuestName());
						end
					else
						DEFAULT_CHAT_FRAME:AddMessage("|cFFDF4444" .. L["Quest abandoned: "] .. GetQuestLogTitle(self.LogPosition) .. "|r")
						PlaySound("igQuestFailed")
						AbandonQuest()
					end

					SelectQuestLogEntry(intCurrentSelectedIndex);
					
				elseif (IsAltKeyDown()) then -- Open quest in full log
					ShowUIPanel(QuestLogFrame);
					QuestLog_OpenToQuest(self.LogPosition, true);
					
				elseif (IsControlKeyDown()) then -- Track quest
					local _, _, _, _, _, _, _, _, questID = GetQuestLogTitle(self.LogPosition);
					SetSuperTrackedQuestID(questID)
				else -- Open quest based on option
				
					if (db.ZonesAndQuests.QuestClicksOpenFullQuestLog == true) then
						ShowUIPanel(QuestLogFrame);
					else
						local selectedIsComplete = select(7, GetQuestLogTitle(self.LogPosition));
						if (selectedIsComplete and GetQuestLogIsAutoComplete()) then
							ShowUIPanel(QuestLogFrame);
						end
					end
					QuestLog_OpenToQuest(self.LogPosition, true);
				end
			end
		else
			local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(self.LogPosition);
			if (self.isHeader == 1) then
				if (IsAltKeyDown()) then
					QuestTracker:DisplayAltRightClickMenu(self)		
				else
					if (db.ZonesAndQuests.AllowHiddenQuests == true) then
						QuestTracker:DisplayRightClickMenu(self)
					end
				end
			else
				if (db.ZonesAndQuests.AllowHiddenQuests == true) then
					if (IsQuestWatched(self.LogPosition) == nil) then
						if (GetNumQuestWatches() >= 25) then
							UIErrorsFrame:AddMessage(format(QUEST_WATCH_TOO_MANY, 25), 1.0, 0.1, 0.1, 1.0);
						else
							AddQuestWatch(self.LogPosition)
						end
					else
						RemoveQuestWatch(self.LogPosition)
					end
					QuestTracker:UpdateMinion()
				end
			end
		end
	end)
	objButton:SetScript("OnEnter", function(self)
		if (not(self.isHeader)) then
		
			local intCurrentSelectedIndex = GetQuestLogSelection()
			local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(self.LogPosition);
			if (questTitle == nil) then 
				return nil
			end
			SelectQuestLogEntry(self.LogPosition);
			

			
			if (db.MoveTooltipsRight == true) then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, -50);
			else 
				GameTooltip:SetOwner(self, "ANCHOR_LEFT", 0, -50);
			end
			
			local strQuestDescription, strQuestObjectives = GetQuestLogQuestText();
			local objColour = GetQuestDifficultyColor(level);
			GameTooltip:SetText(questTitle, 0, 1, 0, 1);
			GameTooltip:AddLine(strQuestObjectives, db.Colours.ObjectiveTooltipTextColour.r, db.Colours.ObjectiveTooltipTextColour.g, db.Colours.ObjectiveTooltipTextColour.b, db.Colours.ObjectiveTooltipTextColour.a);
			
			local strQuestTag = ""
			if (isDaily) then
				strQuestTag = strQuestTag .. L["Daily"] .. " "
			end				
			if (questTag) then
				strQuestTag = strQuestTag .. questTag
				if (suggestedGroup > 0) then
					strQuestTag = strQuestTag .. " (" .. suggestedGroup .. ")"
				end
			end				
			GameTooltip:AddLine(strQuestTag, 1, 0, 0, 1);
			
			local intPartyMembers = GetNumGroupMembers();
			local blnIsOnQuest = false
			if (intPartyMembers > 0) then
				GameTooltip:AddLine(L["Party members on quest:"], 0, 1, 0, 1);
				for k = 1, intPartyMembers do
					blnIsOnQuest = IsUnitOnQuest(self.LogPosition, "party" .. k);
					if (blnIsOnQuest == 1) then
						GameTooltip:AddLine(UnitName("party" .. k), 1, 1, 1, 1);
					end
				end				
			end
			
			SelectQuestLogEntry(intCurrentSelectedIndex);
			GameTooltip:Show();
		else
			if (db.ShowHelpTooltips == true) then
				if (db.MoveTooltipsRight == true) then
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0);
				else 
					GameTooltip:SetOwner(self, "ANCHOR_LEFT", 0, 0);
				end
				
				GameTooltip:SetText(L["Zone Header"], 0, 1, 0, 1);
				GameTooltip:AddLine(L["Click to collapse/expand zone"], 1, 1, 1, 1);
				if (db.ZonesAndQuests.AllowHiddenQuests == true) then
					GameTooltip:AddLine(L["Right-click to show hidden quests toggle dropdown menu\n"], 1, 1, 1, 1);
				end
				GameTooltip:AddLine(L["Alt Right-click to show zone collapse/expand dropdown menu\n"], 1, 1, 1, 1);
				GameTooltip:AddLine(L["You can disable help tooltips in general settings"], 0.5, 0.5, 0.5, 1);
				
				GameTooltip:Show();
			end
		end
	end)
	objButton:SetScript("OnLeave", function(self) 
		GameTooltip:Hide() 
	end)
	
	return objButton
end

function QuestTracker:RecycleMinionButton(objButton)
	if (objButton.ItemButton ~= nil) then
		self:RecycleItemButton(objButton.ItemButton)
		objButton.ItemButton = nil
	end
	SorhaQuestLog:RecycleLogButton(objButton)
end

function QuestTracker:GetItemButton(objItem, intLogPosition)
	local objButton = tremove(tblItemButtonCache)
	if (objButton == nil) then
		intNumberOfItemButtons = intNumberOfItemButtons + 1
		objButton = CreateFrame("BUTTON", strItemButtonPrefix .. intNumberOfItemButtons, UIParent, "WatchFrameItemButtonTemplate");		
	end
	
	objButton:Show()
	objButton:SetID(intLogPosition)
	objButton:SetScale(db.ItemButtonScale)
	objButton.ItemID = objItem["ID"]

	SetItemButtonTexture(objButton, objItem["Item"])
	SetItemButtonTextureVertexColor(objButton, 1.0, 1.0, 1.0)
	SetItemButtonCount(objButton, objItem["Charges"]);
	WatchFrameItem_UpdateCooldown(objButton);
	
	_G[objButton:GetName() .."HotKey"]:Hide()	

	objButton.rangeTimer = -1;
	if (LBF) then
		-- If the button groups not made yet then make it
		if not(LBFGroup) then
			LBFGroup = LBF:Group("SorhaQuestLog", "SQLItemButtons")
			LBFGroup:Skin(db.ButtonSkins.SQLItemButtons.SkinID, db.ButtonSkins.SQLItemButtons.Gloss, db.ButtonSkins.SQLItemButtons.Backdrop, db.ButtonSkins.SQLItemButtons.Colors)
			LBFGroup.SkinID = db.ButtonSkins.SQLItemButtons.SkinID or "DreamLayout"
			LBFGroup.Backdrop = db.ButtonSkins.SQLItemButtons.Backdrop
			LBFGroup.Gloss = db.ButtonSkins.SQLItemButtons.Gloss
			LBFGroup.Colors = db.ButtonSkins.SQLItemButtons.Colors
		end
			
		LBFGroup:AddButton(objButton, tblItemButtonLBFData)
		objButton:RegisterEvent("BAG_UPDATE_COOLDOWN")
	end

	if (ItemHasRange(objItem["Link"]) ~= nil) then
		objButton:RegisterEvent("PLAYER_TARGET_CHANGED")
		objButton:SetScript("OnUpdate", function(self, elapsed)
			self.rangeTimer = self.rangeTimer - elapsed
			if self.rangeTimer <= 0 then
				if IsQuestLogSpecialItemInRange(self:GetID()) == 0 then
					SetItemButtonTextureVertexColor(self, 0.8, 0.1, 0.1)
				else
					SetItemButtonTextureVertexColor(self, 1.0, 1.0, 1.0)
				end
				self.rangeTimer = TOOLTIP_UPDATE_TIME
			end
		end)
	end
	
	objButton:SetScript("OnEvent", function(self, event)
		if (event == "PLAYER_TARGET_CHANGED") then
			self.rangeTimer = -1
		elseif (event == "BAG_UPDATE_COOLDOWN") then
			local objCooldown = _G[self:GetName() .. "Cooldown"]
			local startTime, duration, enable = GetItemCooldown(self.ItemID)
			if startTime > 0 and duration > 0 and enable > 0 then
				objCooldown:SetCooldown(startTime, duration)
				objCooldown:Show()
			else
				objCooldown:Hide()
			end
		end
	end)

	
	return objButton
end

function QuestTracker:RecycleItemButton(objButton)
	objButton:SetParent(UIParent)
	objButton:ClearAllPoints()
	objButton:Hide()
	if (LBF) then
		LBFGroup:RemoveButton(objButton)
	end	
	objButton:SetScript("OnUpdate", nil)
	objButton:SetScript("OnEvent", nil)
	objButton:UnregisterEvent("BAG_UPDATE_COOLDOWN")
	objButton:UnregisterEvent("PLAYER_TARGET_CHANGED")
	tinsert(tblItemButtonCache, objButton)
end

--Minion
function QuestTracker:CreateMinionLayout()
	fraMinionAnchor = SorhaQuestLog:doCreateFrame("FRAME","SQLQuestMinionAnchor",UIParent,db.MinionWidth,20,1,"BACKGROUND",1, db.MinionLocation.Point, UIParent, db.MinionLocation.RelativePoint, db.MinionLocation.X, db.MinionLocation.Y, 1)
	
	fraMinionAnchor:SetMovable(true)
	fraMinionAnchor:SetClampedToScreen(true)
	fraMinionAnchor:RegisterForDrag("LeftButton")
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
		if (db.ShowHelpTooltips == true) then
			if (db.MoveTooltipsRight == true) then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0);
			else 
				GameTooltip:SetOwner(self, "ANCHOR_LEFT", 0, 0);
			end
			
			GameTooltip:SetText(L["Quest Minion Anchor"], 0, 1, 0, 1);
			GameTooltip:AddLine(L["Drag this to move the Quest minion when it is unlocked.\n"], 1, 1, 1, 1);
			local strOutput = ""
			if (db.ShowNumberOfQuests == true) then
				strOutput = strOutput .. L["Displays # of quests you have in your log and the max limit\n"]
			end
			if (db.ShowNumberOfDailyQuests == true) then
				strOutput = strOutput .. L["Displays # of daily quests you have done today of the max limit\n"]
			end			
			GameTooltip:AddLine(strOutput, 1, 1, 1, 1);
			GameTooltip:AddLine(L["You can disable help tooltips in general settings"], 0.5, 0.5, 0.5, 1);
			
			GameTooltip:Show();
		end
	end)
	fraMinionAnchor:SetScript("OnLeave", function(self) 
		GameTooltip:Hide()
	end)
	
	fraMinionAnchor:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,	insets = {left = 5, right = 3, top = 3, bottom = 5}})
	fraMinionAnchor:SetBackdropColor(0, 1, 0, 0)
	fraMinionAnchor:SetBackdropBorderColor(0.5, 0.5, 0, 0)
	
	-- Quests Anchor
	fraMinionAnchor.fraQuestsAnchor = SorhaQuestLog:doCreateLooseFrame("FRAME","SQLQuestsAnchor",fraMinionAnchor, fraMinionAnchor:GetWidth(),1,1,"LOW",1,1)
	fraMinionAnchor.fraQuestsAnchor:SetPoint("TOPLEFT", fraMinionAnchor, "TOPLEFT", 0, 0);
	fraMinionAnchor.fraQuestsAnchor:SetBackdropColor(0, 0, 0, 0)
	fraMinionAnchor.fraQuestsAnchor:SetBackdropBorderColor(0,0,0,0)
	fraMinionAnchor.fraQuestsAnchor:SetAlpha(0)
	
	-- Number of quests fontstring/title fontstring
	fraMinionAnchor.objFontString = fraMinionAnchor:CreateFontString(nil, "OVERLAY");
	fraMinionAnchor.objFontString:SetFont(LSM:Fetch("font", db.Fonts.MinionTitleFont), db.Fonts.MinionTitleFontSize, db.Fonts.MinionTitleFontOutline)
	fraMinionAnchor.objFontString:SetJustifyH("LEFT")
	fraMinionAnchor.objFontString:SetJustifyV("TOP")
	fraMinionAnchor.objFontString:SetText("");
	if (db.Fonts.MinionTitleFontShadowed == true) then
		fraMinionAnchor.objFontString:SetShadowColor(0.0, 0.0, 0.0, 1.0)
	else
		fraMinionAnchor.objFontString:SetShadowColor(0.0, 0.0, 0.0, 0.0)
	end
	fraMinionAnchor.objFontString:SetShadowOffset(1, -1)

	
	-- Show/Hide hidden quest button
	fraMinionAnchor.buttonShowHidden = SorhaQuestLog:doCreateLooseFrame("BUTTON","SQLShowHiddenButton",fraMinionAnchor,16,16,1,"LOW",1,1)
	fraMinionAnchor.buttonShowHidden:SetPoint("TOPLEFT", fraMinionAnchor, "TOPLEFT", 0, 2);
	fraMinionAnchor.buttonShowHidden:SetBackdrop({bgFile="Interface\\AddOns\\SorhaQuestLog\\Textures\\button1.tga", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=-0, right=0, top=0, bottom=0}})
	fraMinionAnchor.buttonShowHidden:SetBackdropBorderColor(0, 0, 0, 0)
	
	-- Show/Hide hidden quest button hover
	fraMinionAnchor.buttonShowHiddenHover = SorhaQuestLog:doCreateLooseFrame("FRAME","SQLShowHiddenButtonHover",fraMinionAnchor.buttonShowHidden,fraMinionAnchor.buttonShowHidden:GetWidth(),fraMinionAnchor.buttonShowHidden:GetHeight(),1,"LOW",1,1)
	fraMinionAnchor.buttonShowHiddenHover:SetPoint("TOPLEFT", fraMinionAnchor.buttonShowHidden, "TOPLEFT", 0, 0);
	fraMinionAnchor.buttonShowHiddenHover:SetBackdrop({bgFile="Interface\\AddOns\\SorhaQuestLog\\Textures\\button1_hover.tga", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=0, tileSize=0, edgeSize=1, insets={left=-0, right=0, top=0, bottom=0}})
	fraMinionAnchor.buttonShowHiddenHover:SetBackdropColor(0, 0, 1, 1)
	fraMinionAnchor.buttonShowHiddenHover:SetBackdropBorderColor(0,0,0,0)
	fraMinionAnchor.buttonShowHiddenHover:SetAlpha(0)
	
	-- Show/Hide hidden quest button events
	fraMinionAnchor.buttonShowHidden:RegisterForClicks("AnyUp")
	fraMinionAnchor.buttonShowHidden:SetScript("OnEnter", function(self) 
		fraMinionAnchor.buttonShowHiddenHover:SetAlpha(1) 
		if (db.ShowHelpTooltips == true) then
			if (db.MoveTooltipsRight == true) then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0);
			else 
				GameTooltip:SetOwner(self, "ANCHOR_LEFT", 0, 0);
			end
			
			GameTooltip:SetText(L["Show all quests button"], 0, 1, 0, 1);
			GameTooltip:AddLine(L["Enable to show all hidden quests"], 1, 1, 1, 1);
			GameTooltip:AddLine(L["You can disable help tooltips in general settings"], 0.5, 0.5, 0.5, 1);
			
			GameTooltip:Show();
		end
	end)
	fraMinionAnchor.buttonShowHidden:SetScript("OnLeave", function(self) 
		fraMinionAnchor.buttonShowHiddenHover:SetAlpha(0) 
		GameTooltip:Hide()
	end)	
	fraMinionAnchor.buttonShowHidden:SetScript("OnClick", function() 
		dbChar.ZonesAndQuests.ShowAllQuests = not dbChar.ZonesAndQuests.ShowAllQuests
		if (dbChar.ZonesAndQuests.ShowAllQuests == true) then
			fraMinionAnchor.buttonShowHidden:SetBackdropColor(0, 0.3, 1, 1)
		else
			fraMinionAnchor.buttonShowHidden:SetBackdropColor(0.5, 0.5, 0.5, 1)
		end
		self:UpdateMinion()
	end)
	
	fraMinionAnchor.BorderFrame = SorhaQuestLog:doCreateFrame("FRAME","SQLQuestMinionBorder", fraMinionAnchor, db.MinionWidth,40,1,"BACKGROUND",1, "TOPLEFT", fraMinionAnchor, "TOPLEFT", 0, 0, 1)
	fraMinionAnchor.BorderFrame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,	insets = {left = 5, right = 3, top = 3, bottom = 5}})
	fraMinionAnchor.BorderFrame:SetBackdropColor(db.Colours.MinionBackGroundColour.r, db.Colours.MinionBackGroundColour.g, db.Colours.MinionBackGroundColour.b, db.Colours.MinionBackGroundColour.a)
	fraMinionAnchor.BorderFrame:SetBackdropBorderColor(db.Colours.MinionBorderColour.r, db.Colours.MinionBorderColour.g, db.Colours.MinionBorderColour.b, db.Colours.MinionBorderColour.a)
	fraMinionAnchor.BorderFrame:Show()
	
	blnMinionInitialized = true
	self:MinionAnchorUpdate(false)
	self:doHiddenQuestsUpdate()	-- Update show/hide hidden quests button position/visibility etc
end

function QuestTracker:UpdateMinion()
	blnMinionUpdating = true

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
	
	-- Setup variables
	local intSpacingIncrease = 0
	local intLargestWidth = 20
	local blnLargestWidthIsHeader = false
	local intHeaderOutlineOffset = 0
	local intQuestOutlineOffset = 0
	local intObjectiveOutlineOffset = 0
	local intYPosition = 0
	local intInitialYOffset = 0
	local intButtonSize = intItemButtonSize * db.ItemButtonScale
	local intQuestOffset =  db.ZonesAndQuests.QuestTitleIndent
	local intObjectiveOffset =  db.ZonesAndQuests.ObjectivesIndent
	local intQuestWithItemButtonOffset = intQuestOffset + intButtonSize
	
	-- Reset was click to update boolean		
	blnWasAClick = false	
	
	-- If this isn't the first get of quest info store the current info for later use
	if not(curQuestInfo == nil) then
		oldQuestInfo = curQuestInfo
		blnFirstUpdate = false
	end
	curQuestInfo = self:GetQuestLogInformation()

	-- Quest/Objective complete Sounds
	if (blnFirstUpdate == false) then
		self:CheckQuestStateChange()
	end	
	
	--Add in slight offsets for outlined text to try stop overlap
	if (db.Fonts.HeaderFontOutline == "THICKOUTLINE") then
		intHeaderOutlineOffset = 2
	elseif (db.Fonts.HeaderFontOutline == "OUTLINE") then
		intHeaderOutlineOffset = 1
	end
	if (db.Fonts.QuestFontOutline == "THICKOUTLINE") then
		intQuestOutlineOffset = 1.5
	elseif (db.Fonts.QuestFontOutline == "OUTLINE") then
		intQuestOutlineOffset = 0.5
	end
	if (db.Fonts.ObjectiveFontOutline == "THICKOUTLINE") then
		intObjectiveOutlineOffset = 1.5
	elseif (db.Fonts.ObjectiveFontOutline == "OUTLINE") then
		intObjectiveOutlineOffset = 0.5
	end	
		
	-- Number of quests title display
	if (curQuestInfo["IsZonesWithTrackedQuests"] == false and db.AutoHideTitle == true) then
		fraMinionAnchor.objFontString:SetText("");
		fraMinionAnchor.buttonShowHidden:Hide()	
	else
		if (db.ZonesAndQuests.AllowHiddenQuests == true) then
			fraMinionAnchor.buttonShowHidden:Show()
		end
		
		if (db.ShowNumberOfQuests == true or db.ShowNumberOfDailyQuests == true or db.ZonesAndQuests.AllowHiddenQuests == true) then
			intYPosition = -db.Fonts.MinionTitleFontSize - db.Fonts.MinionTitleFontLineSpacing;
		else
			intYPosition = -2 - db.Fonts.MinionTitleFontLineSpacing;
		end
		
		if (db.ShowNumberOfQuests == true or db.ShowNumberOfDailyQuests == true) then
			fraMinionAnchor.objFontString:SetFont(LSM:Fetch("font", db.Fonts.MinionTitleFont), db.Fonts.MinionTitleFontSize, db.Fonts.MinionTitleFontOutline)
			fraMinionAnchor.objFontString:SetSpacing(db.Fonts.MinionTitleFontLineSpacing)
			if (db.Fonts.MinionTitleFontShadowed == true) then
				fraMinionAnchor.objFontString:SetShadowColor(0.0, 0.0, 0.0, 1.0)
			else
				fraMinionAnchor.objFontString:SetShadowColor(0.0, 0.0, 0.0, 0.0)
			end
			
			local strText = ""
			if (db.ShowNumberOfQuests == true) then
				strText = strText .. strInfoColour .. curQuestInfo["NoQuests"] .. "/25 |r"
			end
			if (db.ShowNumberOfDailyQuests == true) then
				strText = strText ..  strInfoColour .. "(" .. GetDailyQuestsCompleted() .. ")|r"
			end
			
			
			fraMinionAnchor.objFontString:SetText(strText);
			if (fraMinionAnchor.objFontString:GetWidth() > intLargestWidth) then
				if (db.ZonesAndQuests.AllowHiddenQuests == true) then
					intLargestWidth = fraMinionAnchor.objFontString:GetWidth() + 20 -- Offset for the show/hide button pushing the fontstring accross
				else
					intLargestWidth = fraMinionAnchor.objFontString:GetWidth()
				end
			end
		else
			fraMinionAnchor.objFontString:SetText("");
		end
	end
	fraMinionAnchor:SetWidth(db.MinionWidth)
	
	-- Update LDB 
	if (LDB) then
		if (SorhaQuestLog.SQLBroker ~= nil) then
			SorhaQuestLog.SQLBroker.text = strInfoColour .. curQuestInfo["NoQuests"] .. "/25|r"
		end
	end

	
	intInitialYOffset = intYPosition;
	
	-- Zone/Quest buttons
	local objButton = nil
	for k, ZoneInstance in pairs(curQuestInfo["Zones"]) do
		if (curQuestInfo["IsZonesWithTrackedQuests"] == false and db.AutoHideTitle == true) then
			break
		end
		
		if (not(db.ZonesAndQuests.AllowHiddenQuests == true and db.ZonesAndQuests.QuestHeadersHideWhenEmpty == true and dbChar.ZoneIsAllHiddenQuests[ZoneInstance["Title"]] == true) or (dbChar.ZonesAndQuests.ShowAllQuests == true)) then
			if (db.ZonesAndQuests.HideZoneHeaders == false) then
				objButton = self:GetMinionButton()
				objButton.LogPosition = ZoneInstance["LogPosition"]
				objButton.isHeader = 1
				objButton.isCollapsed = ZoneInstance["Status"]
				objButton.intOffset = 0
		
				local strPrefix = strHeaderColour .. "- "
				if (ZoneInstance["Status"] == 1) then
					strPrefix = strHeaderColour .. "+ "
				end

				-- objButton:SetPoint("TOPLEFT", fraMinionAnchor, "TOPLEFT", 0, intYPosition - intHeaderOutlineOffset)
				objButton.objFontString1:SetPoint("TOPLEFT", objButton, "TOPLEFT", 0, 0);
				objButton.objFontString1:SetFont(LSM:Fetch("font", db.Fonts.HeaderFont), db.Fonts.HeaderFontSize, db.Fonts.HeaderFontOutline)
				objButton.objFontString1:SetSpacing(db.Fonts.HeaderFontLineSpacing)
				if (db.Fonts.HeaderFontShadowed == true) then
					objButton.objFontString1:SetShadowColor(0.0, 0.0, 0.0, 1.0)
				else
					objButton.objFontString1:SetShadowColor(0.0, 0.0, 0.0, 0.0)
				end
				
				if (db.ZonesAndQuests.ShowHiddenCountOnZones == true and db.ZonesAndQuests.AllowHiddenQuests == true) then
					if (ZoneInstance["NumHidden"] > 0) then
						objButton.objFontString1:SetText(strPrefix .. ZoneInstance["Title"] .. "|r (" .. strInfoColour .. ZoneInstance["NumHidden"] .. "/" .. ZoneInstance["NumQuests"] .." Hidden)|r");	
					else
						objButton.objFontString1:SetText(strPrefix .. ZoneInstance["Title"] .. "|r");
					end
				else
					objButton.objFontString1:SetText(strPrefix .. ZoneInstance["Title"] .. "|r");
				end
				
				objButton:SetWidth(db.MinionWidth)
				--
				if (objButton.objFontString1:GetWidth() > intLargestWidth) then
					intLargestWidth = objButton.objFontString1:GetWidth()
					blnLargestWidthIsHeader = true
				end
				--
				objButton.objFontString1:SetWidth(db.MinionWidth)
				
				intSpacingIncrease = objButton.objFontString1:GetHeight() + intHeaderOutlineOffset + db.Fonts.HeaderFontLineSpacing
				objButton:SetHeight(intSpacingIncrease)
				tinsert(tblUsingButtons, objButton)

				objButton:SetPoint("TOPLEFT", fraMinionAnchor.fraQuestsAnchor, "TOPLEFT", 0, intYPosition - intHeaderOutlineOffset)
				intYPosition = intYPosition - intSpacingIncrease
			end
			-- Create each quest in zone
			for k2, QuestInstance in pairs(ZoneInstance["Quests"]) do
				if (QuestInstance["IsHidden"] == false or db.ZonesAndQuests.AllowHiddenQuests == false or dbChar.ZonesAndQuests.ShowAllQuests == true) then

					local blnHasShownButton = false
					local intThisQuestsOffset = intQuestOffset
					if (db.ShowItemButtons == true and QuestInstance["QuestItem"]) then -- Item Buttons on and has a button
						if (db.HideItemButtonsForCompletedQuests == false or (db.HideItemButtonsForCompletedQuests == true and not(QuestInstance["IsComplete"] and QuestInstance["IsComplete"] > 0))) then -- Button not hidden because of completion
							blnHasShownButton = true
							if (db.IndentItemButtons == true and db.MoveTooltipsRight == false) then
								intThisQuestsOffset = intQuestWithItemButtonOffset
							end
						end
					end
					if (db.IndentItemButtonQuestsOnly == false and db.IndentItemButtons == true and db.MoveTooltipsRight == false) then
						intThisQuestsOffset = intQuestWithItemButtonOffset				
					end

					objButton = self:GetMinionButton()
					objButton.LogPosition = QuestInstance["LogPosition"]
					-- objButton:SetPoint("TOPLEFT", fraMinionAnchor, "TOPLEFT", intThisQuestsOffset, intYPosition)
					objButton.intOffset = intThisQuestsOffset
					
					-- Get quest text
					strQuestTitle, strObjectiveText = self:GetQuestText(QuestInstance)
					
					-- Setup quest title string
					objButton.objFontString1:SetPoint("TOPLEFT", objButton, "TOPLEFT", 0, 0);
					objButton.objFontString1:SetFont(LSM:Fetch("font", db.Fonts.QuestFont), db.Fonts.QuestFontSize, db.Fonts.QuestFontOutline)
					objButton.objFontString1:SetSpacing(db.Fonts.QuestFontLineSpacing)
					if (db.Fonts.QuestFontShadowed == true) then
						objButton.objFontString1:SetShadowColor(0.0, 0.0, 0.0, 1.0)
					else
						objButton.objFontString1:SetShadowColor(0.0, 0.0, 0.0, 0.0)
					end
					
					objButton.objFontString1:SetText(strQuestTitle);

					-- Setup quest objectives string
					objButton.objFontString2:SetFont(LSM:Fetch("font", db.Fonts.ObjectiveFont), db.Fonts.ObjectiveFontSize, db.Fonts.ObjectiveFontOutline)
					objButton.objFontString2:SetSpacing(db.Fonts.ObjectiveFontLineSpacing)
					if (db.Fonts.ObjectiveFontShadowed == true) then
						objButton.objFontString2:SetShadowColor(0.0, 0.0, 0.0, 1.0)
					else
						objButton.objFontString2:SetShadowColor(0.0, 0.0, 0.0, 0.0)
					end
					
					objButton.objFontString2:SetText(strObjectiveText);			
					
					objButton:SetWidth(db.MinionWidth - intThisQuestsOffset)

					-- Find out if either string is larger then the current largest string
					if (objButton.objFontString1:GetWidth() + intThisQuestsOffset > intLargestWidth) then
						intLargestWidth = objButton.objFontString1:GetWidth() + intThisQuestsOffset*2
						blnLargestWidthIsHeader = false
					end
					if (objButton.objFontString2:GetWidth() + (intThisQuestsOffset + intObjectiveOffset) > intLargestWidth) then
						intLargestWidth = objButton.objFontString2:GetWidth() + intThisQuestsOffset + intObjectiveOffset
						blnLargestWidthIsHeader = false
					end

					objButton.objFontString1:SetWidth(db.MinionWidth - intThisQuestsOffset)
					
					-- Set second fontstring of the buttons position
					local intSecondFSOffset = objButton.objFontString1:GetHeight() + intQuestOutlineOffset + db.Fonts.QuestFontLineSpacing;
					objButton.objFontString2:SetPoint("TOPLEFT", objButton, "TOPLEFT", intObjectiveOffset, -intSecondFSOffset);
					objButton.objFontString2:SetWidth(db.MinionWidth - intThisQuestsOffset - intObjectiveOffset)
					
					-- Find spacing needed for next button
					intSpacingIncrease = objButton.objFontString2:GetHeight() + intObjectiveOutlineOffset + intSecondFSOffset				
				
					-- If theres an item button to be shown add it
					if (blnHasShownButton == true) then
						local objItem = QuestInstance["QuestItem"]
						local objItemButton = self:GetItemButton(objItem, QuestInstance["LogPosition"])
						objItemButton:SetParent(objButton)

						if (db.MoveTooltipsRight == true) then
							objItemButton:SetPoint("TOPLEFT", objButton, "TOPRIGHT", (8 * (1 / objItemButton:GetScale())), 0)
						else
							if (db.IndentItemButtons == true) then
								objItemButton:SetPoint("TOPRIGHT", objButton, "TOPLEFT", 0, 0)
							else
								objItemButton:SetPoint("TOPRIGHT", objButton, "TOPLEFT", -(16 * (1 / objItemButton:GetScale())), 0)
							end
						end
						
						-- If a button is heigher then its quest then expand the quest frame to stop overlapping buttons
						if (intButtonSize > intSpacingIncrease) then
							intSpacingIncrease = intButtonSize
							objButton.objFontString1:SetHeight(intButtonSize)
						end
						objButton.ItemButton = objItemButton
					end
					objButton:SetHeight(intSpacingIncrease)
					tinsert(tblUsingButtons, objButton)

					objButton:SetPoint("TOPLEFT", fraMinionAnchor.fraQuestsAnchor, "TOPLEFT", intThisQuestsOffset, intYPosition)
					intYPosition = intYPosition - intSpacingIncrease - db.Fonts.ObjectiveFontLineSpacing - db.ZonesAndQuests.QuestAfterPadding;
				end
			end
		end
	end

	-- Auto collapse
	local intBorderWidth = db.MinionWidth
	if (db.MinionCollapseToLeft == true) then
		if (intLargestWidth < db.MinionWidth) then
			fraMinionAnchor:SetWidth(intLargestWidth)
			intBorderWidth = intLargestWidth
			
			for k, objButton in pairs(tblUsingButtons) do
				objButton.objFontString1:SetWidth(intLargestWidth - objButton.intOffset)
				objButton:SetWidth(intLargestWidth - objButton.intOffset)
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
	
	-- Reposition/Resize the border and the Achievements Anchor based on grow upwards option
	fraMinionAnchor.BorderFrame:ClearAllPoints()
	if (db.GrowUpwards == false) then
		fraMinionAnchor.BorderFrame:SetPoint("TOPLEFT", fraMinionAnchor.fraQuestsAnchor, "TOPLEFT", -6, 6);
		fraMinionAnchor.BorderFrame:SetHeight((-intYPosition) + 6 + fraMinionAnchor:GetHeight()/2)
		fraMinionAnchor.fraQuestsAnchor:ClearAllPoints()
		fraMinionAnchor.fraQuestsAnchor:SetPoint("TOPLEFT", fraMinionAnchor, "TOPLEFT", 0, 0);
	else
		fraMinionAnchor.BorderFrame:SetPoint("TOPLEFT", fraMinionAnchor.fraQuestsAnchor, "TOPLEFT", -6,  6 + intInitialYOffset);
		fraMinionAnchor.BorderFrame:SetHeight((-intYPosition) + fraMinionAnchor:GetHeight() - 2)
		fraMinionAnchor.fraQuestsAnchor:ClearAllPoints()
		fraMinionAnchor.fraQuestsAnchor:SetPoint("TOPLEFT", fraMinionAnchor, "TOPLEFT", 0, -intYPosition+5);
	end

	blnMinionUpdating = false
end 

--Quest minion
function QuestTracker:GetQuestText(QuestInstance)
	local strLevelColor = ""
	local strTitleColor = ""
	
	-- Get quest level colour
	if (db.ZonesAndQuests.QuestLevelColouringSetting == "Level") then
		local objColour = GetQuestDifficultyColor(QuestInstance["Level"]);	
		strLevelColor = format("|c%02X%02X%02X%02X", 255, objColour.r * 255, objColour.g * 255, objColour.b * 255);
	
	elseif (db.ZonesAndQuests.QuestLevelColouringSetting == "Completion") then
		strLevelColor = self:GetCompletionColourString(QuestInstance["CompletionLevel"])
	
	elseif (db.ZonesAndQuests.QuestLevelColouringSetting == "Done/Undone") then
		if (QuestInstance["IsComplete"] and QuestInstance["IsComplete"] > 0) then
			strLevelColor = strObjective100Colour
		else
			strLevelColor = strObjective00to24Colour
		end
	
	else
		strLevelColor = strQuestLevelColour
	end
	
	-- Get quest title colour
	if (db.ZonesAndQuests.QuestTitleColouringSetting == "Level") then
		local objColour = GetQuestDifficultyColor(QuestInstance["Level"]);	
		strTitleColor = format("|c%02X%02X%02X%02X", 255, objColour.r * 255, objColour.g * 255, objColour.b * 255);
	
	elseif (db.ZonesAndQuests.QuestTitleColouringSetting == "Completion") then
		strTitleColor = self:GetCompletionColourString(QuestInstance["CompletionLevel"])
	
	elseif (db.ZonesAndQuests.QuestTitleColouringSetting == "Done/Undone") then
		if (QuestInstance["IsComplete"] and QuestInstance["IsComplete"] > 0) then
			strTitleColor = strObjective100Colour
		else
			strTitleColor = strObjective00to24Colour
		end
	
	else
		strTitleColor = strQuestTitleColour
	end
	
	
	local strQuestReturnText = ""
	local blnShowBrackets = false
	local blnFirstThing = true
	-- Quest level
	if (db.ZonesAndQuests.ShowQuestLevels == true) then
		strQuestReturnText = strQuestReturnText .. QuestInstance["Level"]
		blnShowBrackets = true
		blnFirstThing = false
	end
		
	-- PVP, RAID, Group, etc tags
	if (QuestInstance["Tag"] ~= nil) then
		if (db.ZonesAndQuests.QuestTagsLength == "Full" and dicLongQuestTags[QuestInstance["Tag"]] ~= nil) then
			if (blnFirstThing == true) then
				strQuestReturnText = strQuestReturnText .. dicLongQuestTags[QuestInstance["Tag"]]
			else
				strQuestReturnText = strQuestReturnText .. " " .. dicLongQuestTags[QuestInstance["Tag"]]
			end
			
			blnShowBrackets = true
			blnFirstThing = false
		elseif (db.ZonesAndQuests.QuestTagsLength == "Short" and dicQuestTags[QuestInstance["Tag"]] ~= nil) then
			strQuestReturnText = strQuestReturnText .. dicQuestTags[QuestInstance["Tag"]]
			blnShowBrackets = true
			blnFirstThing = false
		end		
	end
	
	if (QuestInstance["SuggestedGroup"] > 0 and db.ZonesAndQuests.QuestTagsLength ~= "None") then
		strQuestReturnText = strQuestReturnText .. QuestInstance["SuggestedGroup"]
		blnShowBrackets = true
		blnFirstThing = false
	end

	if (QuestInstance["IsDaily"]) then
		if (db.ZonesAndQuests.QuestTagsLength == "Full") then
			if (blnFirstThing == true) then
				strQuestReturnText = strQuestReturnText .. dicLongQuestTags["Daily"]
			else
				strQuestReturnText = strQuestReturnText .. " " .. dicLongQuestTags["Daily"]
			end
			blnShowBrackets = true
		elseif (db.ZonesAndQuests.QuestTagsLength == "Short") then
			strQuestReturnText = strQuestReturnText .. dicQuestTags["Daily"]
			blnShowBrackets = true
		end
	end
	
	if (db.ZonesAndQuests.ShowQuestLevels == true or db.ZonesAndQuests.QuestTagsLength ~= "None" and blnShowBrackets == true) then
		strQuestReturnText = strLevelColor .. "[" .. strQuestReturnText
		
		strQuestReturnText = strQuestReturnText .. "]|r "
	end
	
	strQuestReturnText = strQuestReturnText .. strTitleColor .. QuestInstance["Title"] .. "|r"

	-- Completion/failed etc tag
	if (QuestInstance["IsComplete"] and QuestInstance["IsComplete"] < 0) then 
		strQuestReturnText = strQuestReturnText .. strQuestStatusFailed .. L[" (Failed)"] .. "|r"
	elseif (QuestInstance["IsComplete"] and QuestInstance["IsComplete"] > 0) then
		strQuestReturnText = strQuestReturnText .. strQuestStatusDone .. L[" (Done)"] .. "|r"
	elseif (#QuestInstance["ObjectiveList"] == 0) then
		strQuestReturnText = strQuestReturnText .. strQuestStatusGoto .. L[" (goto)"] .. "|r"
	end
	
	-- Hidden tag
	if (QuestInstance["IsHidden"] == true and db.ZonesAndQuests.AllowHiddenQuests == true) then
		strQuestReturnText = strQuestReturnText .. strHeaderColour .. L[" (Hidden)"] .. "|r"
	end 
	
	local strObjectivesReturnText = ""
	
	-- Objectives
	if (#QuestInstance["ObjectiveList"] == 0) then
		-- If no objective and show descriptions on display quest description
		if (db.ZonesAndQuests.ShowDescWhenNoObjectives == true) then
			if (not(QuestInstance["IsComplete"] and QuestInstance["IsComplete"] > 0)) then
				strObjectivesReturnText = strObjectivesReturnText .. strObjectiveDescriptionColour .. " - " .. QuestInstance["ObjectiveDescription"] .. "|r\n"
			else
				if (db.ZonesAndQuests.HideCompletedObjectives == false) then
					strObjectivesReturnText = strObjectivesReturnText .. strObjectiveDescriptionColour .. " - " .. QuestInstance["ObjectiveDescription"] .. "|r\n"
				end
			end	
		end
	else
		-- For each objective in quest
		for k, ObjectiveInstance in pairs(QuestInstance["ObjectiveList"]) do
			if not(db.ZonesAndQuests.HideCompletedObjectives == true and ObjectiveInstance["Status"] == 1) then
				local strObjectiveGradualColour = "|cffffffff"
				local strObjectiveTitleColourOutput = strObjectiveTitleColour
				local strObjectiveStatusColourOutput = strObjectiveStatusColour
				
				-- If somethings uses gradual colours get colour
				if (db.ZonesAndQuests.ObjectiveStatusColouringSetting == "Completion" or db.ZonesAndQuests.ObjectiveTitleColouringSetting == "Completion") then
					strObjectiveGradualColour = self:GetCompletionColourString(ObjectiveInstance["CompletionLevel"])
				end
				
				-- Decide on quest title colour
				if (db.ZonesAndQuests.ObjectiveTitleColouringSetting == "Completion") then
					strObjectiveTitleColourOutput = strObjectiveGradualColour
				elseif (db.ZonesAndQuests.ObjectiveTitleColouringSetting == "Done/Undone") then
					if (ObjectiveInstance["Status"] == nil) then
						strObjectiveTitleColourOutput = strObjective00to24Colour
					else
						strObjectiveTitleColourOutput = strObjective100Colour
					end
				end	

				-- Decide on quest status (0/1 etc) colour
				if (db.ZonesAndQuests.ObjectiveStatusColouringSetting == "Completion") then
					strObjectiveStatusColourOutput = strObjectiveGradualColour
				elseif (db.ZonesAndQuests.ObjectiveStatusColouringSetting == "Done/Undone") then
					if (ObjectiveInstance["Status"] == nil) then
						strObjectiveStatusColourOutput = strObjective00to24Colour
					else
						strObjectiveStatusColourOutput = strObjective100Colour
					end
				end				
				
				-- Depending on quest type display it in a certain way
				if (ObjectiveInstance["Type"] == nil) then
					strOutput = strObjectiveTitleColourOutput .. " - " .. ObjectiveInstance["Text"] .. "|r"		
					
				elseif (ObjectiveInstance["Type"] == "event") then
					if (ObjectiveInstance["Status"] == nil) then
						strOutput = strObjectiveTitleColourOutput .. " - " .. ObjectiveInstance["Text"] .. "|r"
					else
						strOutput = strObjectiveTitleColourOutput .. " - " .. ObjectiveInstance["Text"] .. "|r" .. strObjective100Colour .. " (Done)|r"
					end
					
				elseif (ObjectiveInstance["Type"] == "log") then
					strOutput = strObjectiveTitleColourOutput .. " - " .. ObjectiveInstance["Text"] .. "|r"
					
				elseif (ObjectiveInstance["Type"] == "reputation") then
					if (ObjectiveInstance["Got"] == nil and ObjectiveInstance["Need"] == nil) then
						if (ObjectiveInstance["Status"] == nil) then
							strOutput = strObjectiveTitleColourOutput .. " - " .. ObjectiveInstance["Text"] .. "|r"
						else
							strOutput = strObjectiveTitleColourOutput .. " - " .. ObjectiveInstance["Text"] .. "|r" .. strObjective100Colour .. " (Done)|r"
						end
					else
						strOutput = strObjectiveTitleColourOutput .. " - " .. ObjectiveInstance["Text"] .. ": |r" .. strObjectiveStatusColourOutput .. ObjectiveInstance["Got"] .. " / " .. ObjectiveInstance["Need"] .. "|r"
					end					
				else
					strOutput = strObjectiveTitleColourOutput .. " - " .. ObjectiveInstance["Text"] .. ": |r" .. strObjectiveStatusColourOutput .. ObjectiveInstance["Got"] .. "/" .. ObjectiveInstance["Need"] .. "|r"
				end
				
				strObjectivesReturnText = strObjectivesReturnText .. strOutput .. "\n"
			end
		end
	end
	strQuestReturnText = strtrim(strQuestReturnText)
	strObjectivesReturnText = strtrim(strObjectivesReturnText)
	return strQuestReturnText, strObjectivesReturnText
end

function QuestTracker:CheckQuestStateChange()
	local blnQuestNotFound = false
	local blnObjectiveCompleted = false
	local blnQuestCompleted = false
	local strQuestActionedTitle = ""
	local dicOldQuests = {}
	local dicCurQuests = {}	
	local blnObjectiveAlreadyOutput = false
	local dblPercent = nil
	local r, g, b = nil
	local strMessage = nil
	
	
	-- Compile list of old quests
	for k, ZoneInstance in pairs(oldQuestInfo["Zones"]) do -- Get list of old quests
		for k2, QuestInstance in pairs(ZoneInstance["Quests"]) do
			tinsert(dicOldQuests, QuestInstance)
		end
	end	
	
	-- Compile list of new quests
	for k, ZoneInstance in pairs(curQuestInfo["Zones"]) do -- Get list of current quests
		for k2, QuestInstance in pairs(ZoneInstance["Quests"]) do
			tinsert(dicCurQuests, QuestInstance)
		end
	end
	
	-- For each quest in the old compare it to each quest in the new.
		-- When they match:
			-- Check each old objective against each new objective to check for status changes
			-- Check old quests status against new quest status
	for oldQuestKey, oldQuestInstance in pairs(dicOldQuests) do -- For each quest in the old log
		for curQuestKey, curQuestInstance in pairs(dicCurQuests) do -- For each quest in the new log
			if (oldQuestInstance["ID"] == curQuestInstance["ID"]) then -- If they are the same quest
				
				-- Objective State stuff
				for oldObjectiveKey, oldObjectiveInstance in pairs(oldQuestInstance["ObjectiveList"]) do -- For each of the old quests objectives
					for curObjectiveKey, curObjectiveInstance in pairs(curQuestInstance["ObjectiveList"]) do -- For each of the new quests objectives
						
						blnObjectiveAlreadyOutput = false
						if (oldObjectiveInstance["ID"] == curObjectiveInstance["ID"]) then -- If its the same objective
							if(oldObjectiveInstance["Got"] ~= nil) then
								if (oldObjectiveInstance["Got"] ~= curObjectiveInstance["Got"] and tonumber(oldObjectiveInstance["Got"]) < tonumber(curObjectiveInstance["Got"])) then -- If the objective has changed and has a ?/? format
									-- If LibSink Objectives on: Set a flag so the (Done) message won't output and output current status
									if (db.Notifications.LibSinkObjectiveNotifications == true) then
										blnObjectiveAlreadyOutput = true
										
										if (curObjectiveInstance["Got"] ~= "" and curObjectiveInstance["Need"] ~= "") then
											-- Create message, add quest name if enabled
											if (db.Notifications.DisplayQuestOnObjectiveNotifications == true) then
												strMessage = format("(%s) %s : %s / %s", curQuestInstance["Title"], curObjectiveInstance["Text"], curObjectiveInstance["Got"], curObjectiveInstance["Need"])
											else
												strMessage = format("%s : %s / %s", curObjectiveInstance["Text"], curObjectiveInstance["Got"], curObjectiveInstance["Need"])
											end
											
											-- Account for stupid quests staying in the log a second once complete
											if not(oldObjectiveInstance["Status"] == 1 and curObjectiveInstance["Status"] == nil) then
												if (db.Notifications.LibSinkColourSetting == "Custom") then
													self:Pour(strMessage, db.Colours.NotificationsColour.r, db.Colours.NotificationsColour.g, db.Colours.NotificationsColour.b)
												else
													dblPercent = tonumber(curObjectiveInstance["Got"])/tonumber(curObjectiveInstance["Need"])
													r, g, b = QuestTracker:GetCompletionColourRGB(dblPercent)
													self:Pour(strMessage, r, g, b)
												end
											end
										end
										
									end
								end
							end
							if (oldObjectiveInstance["Status"] == nil and curObjectiveInstance["Status"] == 1) then -- If objective has completed since last test
								
								-- If there has not already been a ?/? message output for this objective and LibSink objectives on
								if (blnObjectiveAlreadyOutput == false and db.Notifications.LibSinkObjectiveNotifications == true) then 
									-- Create message, add quest name if enabled
									if (db.Notifications.DisplayQuestOnObjectiveNotifications == true) then
										strMessage = format("(%s) %s ", curQuestInstance["Title"], curObjectiveInstance["Text"]) .. L["(Complete)"]
									else
										strMessage = format("%s ", curObjectiveInstance["Text"]) .. L["(Complete)"]
									end
									
									
									if (db.Notifications.LibSinkColourSetting == "Custom") then
										self:Pour(strMessage, db.Colours.NotificationsColour.r, db.Colours.NotificationsColour.g, db.Colours.NotificationsColour.b)
									else
										self:Pour(strMessage, db.Colours.ObjectiveDoneColour.r, db.Colours.ObjectiveDoneColour.g, db.Colours.ObjectiveDoneColour.b)
									end
								end
								blnObjectiveCompleted = true
							end
						end
					end
				end
				
				-- Quest State stuff
				if (oldQuestInstance["IsComplete"] == nil and curQuestInstance["IsComplete"] == 1) then -- Has quest been completed since last
					
					-- If enabled display complete message
					if (db.Notifications.ShowQuestCompletesAndFails) then
						self:Pour(L["Quest completed: "] .. curQuestInstance["Title"], db.Colours.NotificationsColour.r, db.Colours.NotificationsColour.g, db.Colours.NotificationsColour.b)
					end
					
					-- Set flag to make sound play
					blnQuestCompleted = true
				elseif (oldQuestInstance["IsComplete"] == nil and curQuestInstance["IsComplete"] == -1) then -- Has quest been failed since last
					
					-- If enabled display failed message
					if (db.Notifications.ShowQuestCompletesAndFails) then
						self:Pour(L["Quest failed: "] .. curQuestInstance["Title"], db.Colours.NotificationsColour.r, db.Colours.NotificationsColour.g, db.Colours.NotificationsColour.b)
					end
				end
			end
		end	
	end
	
	if (blnQuestCompleted == true) then
		if ((GetTime() - intTimeOfLastSound) > 1 and db.Notifications.QuestDoneSound ~= "None") then
			PlaySoundFile(LSM:Fetch("sound", db.Notifications.QuestDoneSound))
			intTimeOfLastSound = GetTime()
		end
	elseif (blnObjectiveCompleted == true) then
		if ((GetTime() - intTimeOfLastSound) > 1 and db.Notifications.ObjectiveDoneSound ~= "None") then
			PlaySoundFile(LSM:Fetch("sound", db.Notifications.ObjectiveDoneSound))
			intTimeOfLastSound = GetTime()
		end
	end
end

function QuestTracker:GetQuestLogInformation()
	local intNoEntries, intNoQuests = GetNumQuestLogEntries();
	local i = 1
	local intEntrys = 0
	local blnIsZonesWithTrackedQuests = false
	local QuestLogInfo = {["NoEntrys"] = 0, ["NoQuests"] = intNoQuests, ["Zones"] = {}, ["NumCollapsedZones"] = 0, ["IsZonesWithTrackedQuests"] = false,}
	local ZoneEntry = nil
	local QuestEntry = {}
	local ObjectiveEntry = {}
	local ItemEntry = {}
	
	local intNumCollapsedZones = 0
	local intNumHidden = 0
	local intNumQuestsInZone = 0
	local intCurrentSelectedIndex = GetQuestLogSelection()
	
	-- For each entry in the quest log
	for i = 1, intNoEntries, 1 do
		local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(i);
		if (questTitle == nil) then
			questTitle = L["Unknown"]
		end

		if (isHeader) then
			-- If no zone data exists create default
			if (dbChar.ZoneIsAllHiddenQuests[questTitle] == nil) then
				dbChar.ZoneIsAllHiddenQuests[questTitle] = false
			end
			
			-- Get zone collapsed state and save to keep log state after login
			if (isCollapsed == nil) then
				dbChar.ZoneIsCollapsed[questTitle] = false
			else
				dbChar.ZoneIsCollapsed[questTitle] = true
			end
			
			
			-- Create new zone entry
			intEntrys = intEntrys + 1
			if not(ZoneEntry == nil) then
				ZoneEntry["NumHidden"] = intNumHidden
				ZoneEntry["NumQuests"] = intNumQuestsInZone
				if (intNumQuestsInZone > 0) then
					if (intNumHidden == intNumQuestsInZone) then
						dbChar.ZoneIsAllHiddenQuests[ZoneEntry["Title"]] = true
					else
						dbChar.ZoneIsAllHiddenQuests[ZoneEntry["Title"]] = false
					end
				end
				if (dbChar.ZoneIsAllHiddenQuests[questTitle] == false) then
					blnIsZonesWithTrackedQuests = true
				end
				
				tinsert(QuestLogInfo["Zones"], ZoneEntry)
				intNumHidden = 0
				intNumQuestsInZone = 0
			end
			if (isCollapsed == 1) then
				intNumCollapsedZones = intNumCollapsedZones + 1
			end
			ZoneEntry = {["Title"] = questTitle, ["Status"] = isCollapsed, ["LogPosition"] = i, ["ID"] = questID, ["HasHidden"] = false, ["NumHidden"] = intNumHidden, ["NumQuests"] = intNumQuestsInZone, ["Quests"] = {}}
		else
			-- Create new zone
			intNumQuestsInZone = intNumQuestsInZone + 1
			intEntrys = intEntrys + 1
			
			QuestEntry = {["Title"] = questTitle, ["Level"] = level, ["Tag"] = questTag, ["IsHidden"] = false, ["SuggestedGroup"] = suggestedGroup, ["IsComplete"] = isComplete, ["IsDaily"] = isDaily, ["LogPosition"] = i, ["ID"] = questID, ["QuestItem"] = nil, ["CompletionLevel"] = 0, ["ObjectiveList"] = {}, ["ObjectiveDescription"] = ""}

			-- Quest item
			local strLink, strItem, intCharges = GetQuestLogSpecialItemInfo(i);
			if (strItem) then
				local strID =  strLink:match("Hitem:(%d+):")
				ItemEntry = {["Link"] = strLink, ["Item"] = strItem, ["Charges"] = intCharges, ["ID"] = strID}
				QuestEntry["QuestItem"] = ItemEntry
			end
			
			-- Get quest text and objective count
			SelectQuestLogEntry(i);
			local strQuestDescription, strQuestObjectiveDescription = GetQuestLogQuestText();
			local intNoOfObjectives = GetNumQuestLeaderBoards(i)
			
			-- Auto hide completed/goto quests
			if (db.ZonesAndQuests.HideCompletedQuests == true) then
				if (isComplete == 1 or intNoOfObjectives == 0) then
					RemoveQuestWatch(i)
				end	
			end

			local isWatched = IsQuestWatched(i)
			
			-- Hidden quest settings
			if (isWatched == nil) then
				intNumHidden = intNumHidden + 1
				QuestEntry["IsHidden"] = true
				ZoneEntry["HasHidden"] = true
			else
				blnIsZonesWithTrackedQuests = true
			end

			local dblQuestCompletionPercent = 0
			local intNumUsedObjectives = 0
			
			QuestEntry["ObjectiveDescription"] = strQuestObjectiveDescription
			
			-- Objectives
			for k = 1, intNoOfObjectives, 1 do
				local leaderboardTxt, itemType, isDone = GetQuestLogLeaderBoard(k,i);

				if not(leaderboardTxt == nil) then
					intNumUsedObjectives = intNumUsedObjectives + 1
					local strObjText = ""
					local strGot = ""
					local strGetTo = ""
					local intCompletion = 0
					local intGot = 0
					local intNeeded = 1
				
					-- Change things based on objective type
					if (itemType == nil) then
						strObjText = leaderboardTxt
						
					elseif (itemType == "event") then
						strObjText = leaderboardTxt
						
					elseif (itemType == "log") then
						strObjText = leaderboardTxt		
						
					elseif (itemType == "spell") then
						strObjText = leaderboardTxt	
						if (isDone == 1) then
							strGot = "1"
						else
							strGot = "0"
						end
						strGetTo = "1"
						
					elseif (itemType == "reputation") then
						local y, z, strObjDesc, strRepHave, strRepNeeded = string.find(leaderboardTxt, "(.*):%s*(.*)%s*/%s*(.*)");
						
						if (strObjDesc == nil) then strObjText = "" else strObjText = strObjDesc end
						if (strRepHave == nil) then strGot = "" else strGot = strtrim(strRepHave) end
						if (strRepNeeded == nil) then strGetTo = "" else strGetTo = strtrim(strRepNeeded) end
						
						for k, RepInstance in pairs(dicRepLevels) do
							if (strGot == RepInstance["MTitle"] or strGot == RepInstance["FTitle"]) then
								intGot = RepInstance["Value"]
							end
							if (strGetTo == RepInstance["MTitle"] or strGetTo == RepInstance["FTitle"]) then
								intNeeded = RepInstance["Value"]
							end
						end
						if (y == nil and z == nil and strObjDesc == nil and strRepHave == nil and strRepNeeded == nil) then
							strObjText = leaderboardTxt
							strGot = nil
							strGetTo = nil
						end
						intCompletion = intGot / intNeeded
					
					else
						local y, z, strObjDesc, intNumGot, intNumNeeded = string.find(leaderboardTxt, "(.*):%s*([%d]+)%s*/%s*([%d]+)");
						if (strObjDesc == nil) then strObjText = "" else strObjText = strObjDesc end
						if (intNumGot == nil) then strGot = 2 else strGot = intNumGot end
						if (intNumNeeded == nil) then strGetTo = 1 else strGetTo = intNumNeeded end
						intCompletion = strGot / strGetTo
					end
		
					if (isDone) then
						intCompletion = 1
					end
					dblQuestCompletionPercent = dblQuestCompletionPercent + intCompletion
					ObjectiveEntry = {["Text"] = strObjText, ["Got"] = strGot, ["Need"] = strGetTo, ["CompletionLevel"] = intCompletion, ["Type"] = itemType, ["Status"] = isDone, ["ID"] = k}
					tinsert(QuestEntry["ObjectiveList"], ObjectiveEntry)
				end
			end
			if (intNoOfObjectives < 1) then
				dblQuestCompletionPercent = 1
			else
				dblQuestCompletionPercent = dblQuestCompletionPercent / intNumUsedObjectives
			end
			QuestEntry["CompletionLevel"] = dblQuestCompletionPercent
			tinsert(ZoneEntry["Quests"], QuestEntry)
		end
	end
	if (ZoneEntry ~= nil) then
		ZoneEntry["NumHidden"] = intNumHidden
		ZoneEntry["NumQuests"] = intNumQuestsInZone
		if (ZoneEntry["NumQuests"] > 0) then
			if (intNumHidden == intNumQuestsInZone) then
				dbChar.ZoneIsAllHiddenQuests[ZoneEntry["Title"]] = true
			else
				dbChar.ZoneIsAllHiddenQuests[ZoneEntry["Title"]] = false
			end
			
			if (dbChar.ZoneIsAllHiddenQuests[questTitle] == false) then
				blnIsZonesWithTrackedQuests = true
			end
		end
		tinsert(QuestLogInfo["Zones"], ZoneEntry)
	end
	QuestLogInfo["NoEntrys"] = intEntrys
	QuestLogInfo["NumCollapsedZones"] = intNumCollapsedZones
	QuestLogInfo["IsZonesWithTrackedQuests"] = blnIsZonesWithTrackedQuests
	
	-- Reset selected entry to what it was before getting data
	SelectQuestLogEntry(intCurrentSelectedIndex);
	
	return QuestLogInfo
end

function QuestTracker:GetCompletionColourString(dblPercent)
	if (dblPercent < 0.25) then
		return strObjective00to24Colour
	elseif (dblPercent >= 0.25 and dblPercent < 0.50) then
		return strObjective25to49Colour
	elseif (dblPercent >= 0.50 and dblPercent < 0.75) then
		return strObjective50to74Colour
	elseif (dblPercent >= 0.75 and dblPercent < 1) then
		return strObjective75to99Colour
	else
		return strObjective100Colour
	end
end

function QuestTracker:GetCompletionColourRGB(dblPercent)
	if (dblPercent < 0.25) then
		return db.Colours.Objective00PlusColour.r, db.Colours.Objective00PlusColour.g, db.Colours.Objective00PlusColour.b
	elseif (dblPercent >= 0.25 and dblPercent < 0.50) then
		return db.Colours.Objective25PlusColour.r, db.Colours.Objective25PlusColour.g, db.Colours.Objective25PlusColour.b
	elseif (dblPercent >= 0.50 and dblPercent < 0.75) then
		return db.Colours.Objective50PlusColour.r, db.Colours.Objective50PlusColour.g, db.Colours.Objective50PlusColour.b
	elseif (dblPercent >= 0.75 and dblPercent < 1) then
		return db.Colours.Objective75PlusColour.r, db.Colours.Objective75PlusColour.g, db.Colours.Objective75PlusColour.b
	else
		return db.Colours.ObjectiveDoneColour.r, db.Colours.ObjectiveDoneColour.g, db.Colours.ObjectiveDoneColour.b
	end
end

function QuestTracker:doHiddenQuestsUpdate()
	-- Show/Hide hidden quests button and move quest count text accordingly
	if (blnMinionInitialized == true) then
		if (db.ZonesAndQuests.AllowHiddenQuests == true) then
			fraMinionAnchor.buttonShowHidden:Show()	
			fraMinionAnchor.buttonShowHiddenHover:Show()
			fraMinionAnchor.objFontString:ClearAllPoints()
			fraMinionAnchor.objFontString:SetPoint("TOPLEFT", fraMinionAnchor, "TOPLEFT", 16, 0);
			if (dbChar.ZonesAndQuests.ShowAllQuests == true) then
				fraMinionAnchor.buttonShowHidden:SetBackdropColor(0, 0.3, 1, 1)
			else
				fraMinionAnchor.buttonShowHidden:SetBackdropColor(0.5, 0.5, 0.5, 1)
			end
		else
			fraMinionAnchor.buttonShowHidden:Hide()	
			fraMinionAnchor.buttonShowHiddenHover:Hide()
			fraMinionAnchor.objFontString:ClearAllPoints()
			fraMinionAnchor.objFontString:SetPoint("TOPLEFT", fraMinionAnchor, "TOPLEFT", 0, 0);
		end		
	end
end

function QuestTracker:DisplayRightClickMenu(objButton)
	local objMenu = CreateFrame("Frame", "SorhaQuestLogMenuThing")
	local intLevel = 1
	local info = {}
	
	objMenu.displayMode = "MENU"
	objMenu.initialize = function(self, intLevel)
		if not intLevel then return end
		wipe(info)
		if intLevel == 1 then
			-- Create the title of the menu
			info.isTitle = 1
			info.text = L["Show/Hide Quests"]
			info.notCheckable = 1
			UIDropDownMenu_AddButton(info, intLevel)
			
			local intCurrentButton = 0
			local curZone = nil
			
			-- Get zone button belongs to
			for k, ZoneInstance in pairs(curQuestInfo["Zones"]) do
				if (ZoneInstance["LogPosition"] == objButton.LogPosition) then
					curZone = ZoneInstance
				end
			end

			-- Show/Hide buttons for each quest
			for k2, QuestInstance in pairs(curZone["Quests"]) do
				info.disabled = nil
				info.isTitle = nil
				info.notCheckable = nil
				info.text = QuestInstance["Title"]
				info.func = function()
					if (IsQuestWatched(QuestInstance["LogPosition"]) == nil) then
						if (GetNumQuestWatches() >= 25) then
							UIErrorsFrame:AddMessage(format(QUEST_WATCH_TOO_MANY, 25), 1.0, 0.1, 0.1, 1.0);
						else
							AddQuestWatch(QuestInstance["LogPosition"])
						end
					else
						RemoveQuestWatch(QuestInstance["LogPosition"])
					end
					QuestLog_Update();
					QuestTracker:UpdateMinion()
				end
				info.checked = IsQuestWatched(QuestInstance["LogPosition"])
				UIDropDownMenu_AddButton(info, intLevel)
			end
	
			-- Hide all button if not all hidden
			if not(curZone["NumHidden"] == curZone["NumQuests"])then
				info.text = L["Hide All"]
				info.disabled = nil
				info.isTitle = nil
				info.notCheckable = 1
				info.func = function()
					for k2, QuestInstance in pairs(curZone["Quests"]) do
						RemoveQuestWatch(QuestInstance["LogPosition"])
					end
					QuestLog_Update();
					QuestTracker:UpdateMinion()
				end
				UIDropDownMenu_AddButton(info, intLevel)
			end
			
			-- Show all button if not all hidden
			if (curZone["NumHidden"] > 0)then
				info.text = L["Show All"]
				info.disabled = nil
				info.isTitle = nil
				info.notCheckable = 1
				info.func = function()
					for k2, QuestInstance in pairs(curZone["Quests"]) do
						if (GetNumQuestWatches() >= 25) then
							UIErrorsFrame:AddMessage(format(QUEST_WATCH_TOO_MANY, 25), 1.0, 0.1, 0.1, 1.0);
							break
						else
							AddQuestWatch(QuestInstance["LogPosition"])
						end
					end
					QuestLog_Update();
					QuestTracker:UpdateMinion()
				end
				UIDropDownMenu_AddButton(info, intLevel)
			end

			-- Close menu item
			info.text = CLOSE
			info.disabled = nil
			info.isTitle = nil
			info.notCheckable = 1
			info.func = function() CloseDropDownMenus() end
			UIDropDownMenu_AddButton(info, intLevel)
		end
	end

	ToggleDropDownMenu(1, nil, objMenu, objButton, 0, 0)
end

function QuestTracker:DisplayAltRightClickMenu(objButton)
	local objMenu = CreateFrame("Frame", "SorhaQuestLogMenuThing")
	local intLevel = 1
	local info = {}
	
	objMenu.displayMode = "MENU"
	objMenu.initialize = function(self, intLevel)
		if not intLevel then return end
		wipe(info)
		if intLevel == 1 then
			-- Create the title of the menu
			info.isTitle = 1
			info.text = L["Expand/Collapse Zones"]
			info.notCheckable = 1
			UIDropDownMenu_AddButton(info, intLevel)
			
			-- Collapse/Expand button for each zone
			for k, ZoneInstance in pairs(curQuestInfo["Zones"]) do
				info.disabled = nil
				info.isTitle = nil
				info.notCheckable = nil
				info.text = ZoneInstance["Title"]
				info.func = function()
					if (ZoneInstance["Status"] == nil) then
						CollapseQuestHeader(ZoneInstance["LogPosition"])
					else
						ExpandQuestHeader(ZoneInstance["LogPosition"])
					end
				end
				info.checked = not(ZoneInstance["Status"])
				UIDropDownMenu_AddButton(info, intLevel)
			end

			-- Collapse all button if not all hidden
			if not(#curQuestInfo["Zones"] == curQuestInfo["NumCollapsedZones"])then
				info.text = L["Collapse All"]
				info.disabled = nil
				info.isTitle = nil
				info.notCheckable = 1
				info.func = function()
					for k, ZoneInstance in pairs(curQuestInfo["Zones"]) do
						CollapseQuestHeader(ZoneInstance["LogPosition"])
					end
				end
				UIDropDownMenu_AddButton(info, intLevel)
			end
			
			-- Expand all button if not all hidden
			if (curQuestInfo["NumCollapsedZones"] > 0)then
				info.text = L["Expand All"]
				info.disabled = nil
				info.isTitle = nil
				info.notCheckable = 1
				info.func = function()
					for k, ZoneInstance in pairs(curQuestInfo["Zones"]) do
						ExpandQuestHeader(ZoneInstance["LogPosition"])
					end
				end
				UIDropDownMenu_AddButton(info, intLevel)
			end

			-- Close menu item
			info.text = CLOSE
			info.disabled = nil
			info.isTitle = nil
			info.notCheckable = 1
			info.func = function() CloseDropDownMenus() end
			UIDropDownMenu_AddButton(info, intLevel)
		end
	end

	ToggleDropDownMenu(1, nil, objMenu, objButton, 0, 0)
end

function QuestTracker:CheckBags()
	for k, intBag in pairs(tblBagsToCheck) do
		for intSlot = 1, GetContainerNumSlots(intBag), 1 do 
			local isQuestItem, questId, isActive = GetContainerItemQuestInfo(intBag, intSlot);
			if (questId ~= nil and isActive == false) then
				local intID = GetContainerItemID(intBag, intSlot)
				if (blnFirstBagCheck == true) then
					tinsert(tblHaveQuestItems, intID)
				else
					if not(tContains(tblHaveQuestItems, intID)) then
						tinsert(tblHaveQuestItems, intID)
						local itemName, itemLink, itemRarity , _, _, _, _, _,_, itemTexture, _ = GetItemInfo(intID)
						local _, _, _, hex = GetItemQualityColor(itemRarity)
						
						hex = "|c" .. hex
						
						local strOutput = nil
						if (db.sink20OutputSink == "Channel") then
							strOutput = UnitName("player") .. " " .. L["picked up a quest starting item: "] .. hex .. itemName .. "|r"
							self:Pour(strOutput, db.Colours.NotificationsColour.r, db.Colours.NotificationsColour.g, db.Colours.NotificationsColour.b,_,_,_,_,_,itemTexture)
						else
							local strItem = ""
							if (db.sink20OutputSink == "ChatFrame") then
								strItem = "|T" .. itemTexture .. ":15|t"
							else
								strItem = "|T" .. itemTexture .. ":20:20:-5|t"
							end
							
							strOutput = L["You picked up a quest starting item: "] .. " " .. strItem .. hex .. itemLink .. "|r"
							self:Pour(strOutput, db.Colours.NotificationsColour.r, db.Colours.NotificationsColour.g, db.Colours.NotificationsColour.b)
						end
						
						-- Play sound if enabled
						if ((GetTime() - intTimeOfLastSound) > 1 and db.Notifications.QuestItemFoundSound ~= "None") then
							PlaySoundFile(LSM:Fetch("sound", db.Notifications.QuestItemFoundSound))
							intTimeOfLastSound = GetTime()
						end
					end
				end
			end
		end
	end
	wipe(tblBagsToCheck)

	if (blnFirstBagCheck == true) then
		blnFirstBagCheck = false
	end
	blnBagCheckUpdating = false
end

function QuestTracker:RefreshZoneHeadersState()
	blnIgnoreUpdateEvents = true
	local intNoEntries, intNoQuests = GetNumQuestLogEntries();

	for i = intNoEntries, 1, -1 do
		local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(i);
		if (dbChar.ZoneIsCollapsed[questTitle] ~= nil) then
			if (dbChar.ZoneIsCollapsed[questTitle] == true) then
				if (isCollapsed == nil) then
					CollapseQuestHeader(i)
				end
			else
				if (isCollapsed == 1) then
					ExpandQuestHeader(i)
				end		
			end
		end
	end
	
	blnIgnoreUpdateEvents = false
end

function QuestTracker:doHandleZoneChange()
	blnIgnoreUpdateEvents = true
	
	local blnNewZone = not(strZone == GetRealZoneText())
	strZone = GetRealZoneText()
	strSubZone = GetSubZoneText()
	local blnChanged = false
	
	if (db.ZonesAndQuests.CollapseOnLeave == true or db.ZonesAndQuests.ExpandOnEnter == true) then
		self:GetQuestLogInformation()
		local numEntries, numQuests = GetNumQuestLogEntries();	
		for i = numEntries, 1, -1 do
			local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(i);
			if (isHeader) then
				if (questTitle == strZone or questTitle == strSubZone) then
					if (db.ZonesAndQuests.ExpandOnEnter == true and isCollapsed) then
						ExpandQuestHeader(i)
						blnChanged = true
					end
				else		
					if (db.ZonesAndQuests.CollapseOnLeave == true and not(isCollapsed) and blnNewZone) then				
						CollapseQuestHeader(i)
						blnChanged = true
					end				
				end
			end
		end
	end
	
	blnIgnoreUpdateEvents = false
	if (blnMinionInitialized == true and blnChanged == true) then
		self:UpdateMinion()
	end
end


--Uniform
function QuestTracker:MinionAnchorUpdate(blnMoveAnchors)
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

function QuestTracker:UpdateColourStrings()
	strMinionTitleColour = format("|c%02X%02X%02X%02X", 255, db.Colours.MinionTitleColour.r * 255, db.Colours.MinionTitleColour.g * 255, db.Colours.MinionTitleColour.b * 255);
	strInfoColour = format("|c%02X%02X%02X%02X", 255, db.Colours.InfoColour.r * 255, db.Colours.InfoColour.g * 255, db.Colours.InfoColour.b * 255);
	strHeaderColour = format("|c%02X%02X%02X%02X", 255, db.Colours.HeaderColour.r * 255, db.Colours.HeaderColour.g * 255, db.Colours.HeaderColour.b * 255);	
	strQuestStatusFailed = format("|c%02X%02X%02X%02X", 255, db.Colours.QuestStatusFailedColour.r * 255, db.Colours.QuestStatusFailedColour.g * 255, db.Colours.QuestStatusFailedColour.b * 255);
	strQuestStatusDone = format("|c%02X%02X%02X%02X", 255, db.Colours.QuestStatusDoneColour.r * 255, db.Colours.QuestStatusDoneColour.g * 255, db.Colours.QuestStatusDoneColour.b * 255);
	strQuestStatusGoto = format("|c%02X%02X%02X%02X", 255, db.Colours.QuestStatusGotoColour.r * 255, db.Colours.QuestStatusGotoColour.g * 255, db.Colours.QuestStatusGotoColour.b * 255);
	strQuestLevelColour = format("|c%02X%02X%02X%02X", 255, db.Colours.QuestLevelColour.r * 255, db.Colours.QuestLevelColour.g * 255, db.Colours.QuestLevelColour.b * 255);
	strQuestTitleColour = format("|c%02X%02X%02X%02X", 255, db.Colours.QuestTitleColour.r * 255, db.Colours.QuestTitleColour.g * 255, db.Colours.QuestTitleColour.b * 255);
	strObjectiveTitleColour = format("|c%02X%02X%02X%02X", 255, db.Colours.ObjectiveTitleColour.r * 255, db.Colours.ObjectiveTitleColour.g * 255, db.Colours.ObjectiveTitleColour.b * 255);
	strObjectiveStatusColour = format("|c%02X%02X%02X%02X", 255, db.Colours.ObjectiveStatusColour.r * 255, db.Colours.ObjectiveStatusColour.g * 255, db.Colours.ObjectiveStatusColour.b * 255);
	strObjective00to24Colour = format("|c%02X%02X%02X%02X", 255, db.Colours.Objective00PlusColour.r * 255, db.Colours.Objective00PlusColour.g * 255, db.Colours.Objective00PlusColour.b * 255);
	strObjective25to49Colour = format("|c%02X%02X%02X%02X", 255, db.Colours.Objective25PlusColour.r * 255, db.Colours.Objective25PlusColour.g * 255, db.Colours.Objective25PlusColour.b * 255);
	strObjective50to74Colour = format("|c%02X%02X%02X%02X", 255, db.Colours.Objective50PlusColour.r * 255, db.Colours.Objective50PlusColour.g * 255, db.Colours.Objective50PlusColour.b * 255);
	strObjective75to99Colour = format("|c%02X%02X%02X%02X", 255, db.Colours.Objective75PlusColour.r * 255, db.Colours.Objective75PlusColour.g * 255, db.Colours.Objective75PlusColour.b * 255);
	strObjective100Colour = format("|c%02X%02X%02X%02X", 255, db.Colours.ObjectiveDoneColour.r * 255, db.Colours.ObjectiveDoneColour.g * 255, db.Colours.ObjectiveDoneColour.b * 255);
	strObjectiveDescriptionColour = format("|c%02X%02X%02X%02X", 255, db.Colours.ObjectiveDescColour.r * 255, db.Colours.ObjectiveDescColour.g * 255, db.Colours.ObjectiveDescColour.b * 255);	
	strObjectiveTooltipTextColour = format("|c%02X%02X%02X%02X", 255, db.Colours.ObjectiveTooltipTextColour.r * 255, db.Colours.ObjectiveTooltipTextColour.g * 255, db.Colours.ObjectiveTooltipTextColour.b * 255);
	
end

function QuestTracker:HandleColourChanges()
	self:UpdateColourStrings()
	if (self:IsVisible() == true) then
		if (blnMinionUpdating == false) then
			blnMinionUpdating = true
			self:ScheduleTimer("UpdateMinion", 0.1)
		end
	end
end

function QuestTracker:ToggleLockState()
	db.MinionLocked = not db.MinionLocked
end

function QuestTracker:IsVisible()
	if (self:IsEnabled() == true and dbCore.Main.HideAll == false) then
		return true
	end
	return false	
end