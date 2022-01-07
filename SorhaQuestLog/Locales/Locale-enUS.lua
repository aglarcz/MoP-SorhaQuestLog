local L = LibStub("AceLocale-3.0"):NewLocale("SorhaQuestLog", "enUS", true)
if not L then return end


--shared


L["Enable Minion"] = true
L["Lock Minion"] = true
L["Show Minion Title"] = true

L["Auto Hide Minion Title"] = true
L["Hide the title when there is nothing to display"] = true

L["Minion Scale"] = true
L["Adjust the scale of the minion"] = true

L["Width"] = true
L["Adjust the width of the minion"] = true

L["Minion Title Font Settings"] = true

L["Font"] = true
L["The font used for this element"] = true

L["Font Outline"] = true
L["The outline that this font will use"] = true

L["Font Size"] = true
L["Controls the font size this font"] = true

L["Shadow Text"] = true
L["Shows/Hides text shadowing"] = true

L["Font Line Spacing"] = true
L["Controls the spacing below each line of this font"] = true

L["Minion Title"] = true
L["Sets the color for Minion Title"] = true

L["Background Colour"] = true
L["Sets the color of the minions background"] = true

L["Border Colour"] = true
L["Sets the color of the minions border"] = true

--Tab titles
L["Main"] = true
L["Fonts"] = true
L["Colours"] = true

--quest
L["Quest Tracker"] = true
L["Quest Tracker Settings"] = true
L["Info Text Font Settings"] = true

L["Zones"] = true
L["Quests"] = true
L["Quest Items"] = true
L["Notifications"] = true



L["Zone Font Settings"] = true
L["Quest Font Settings"] = true
L["Objective Font Settings"] = true

--achive
L["Achievement Tracker"] = true
L["Achievement Settings"] = true



--timer
L["Quest Timers"] = true
L["Quest Timers Tracker"] = true
L["Quest Timer Text Font Settings"] = true
L["Quest Texts"] = true
L["Sets the color for Quest Texts"] = true

--remote
L["Remote Quests Tracker"] = true

--scenario
L["Scenario Settings"] = true
L["Scenario Quests"] = true
L["Scenario Tracker"] = true

L["Header Font Settings"] = true
L["Task Font Settings"] = true
L["Objective Font Settings"] = true
L["The texture the status bars will use"] = true
L["Sets the color for the completed part of the status bar"] = true
L["Sets the color for the un-completed part of the status bar"] = true

		L["Scenario Headers"] = true
		L["Sets the color for Scenario Headers"] = true
		
		L["Scenario Tasks"] = true
		L["Sets the color for Scenario Tasks"] = true
		
		L["Scenario Objectives"] = true
		L["Sets the color for Scenario Objectives"] = true




		








-- QuestText tags
L[" (Failed)"] = true
L[" (Done)"] = true
L[" (goto)"] = true
L[" (Hidden)"] = true

-- Quest tooltip tags
L["Daily"] = true
L["Party members on quest:"] = true

-- Unknown zone headers etc tag
L["Unknown"] = true

-- Notifications tags
L["(Complete)"] = true

-- Quest abandoned message
L["Quest abandoned: "] = true


-- LDB
L["Quests"] = true
L["Sorha Quest Log"] = true

	L["Left-click"] = true
	L["Show/hide All enabled minions"] = true

	L["Shift Left-click"] = true
	L["Show/hide Quest minion"] = true

	L["Alt Left-click"] = true
	L["Show/hide Achievement minion"] = true

	L["Control Left-click"] = true
	-- Nothing

	L["Right-click"] = true
	L["Show options"] = true

	L["Shift Right-click"] = true
	L["Lock/unlock all minions"] = true

	L["Alt Right-click"] = true
	L["Show/hide minion anchors"] = true

	L["Control Right-click"] = true
	-- Nothing

-- Titles
L["Achivement Tracker Title"] = "Achievement Tracker"
L["Quest Timer Frame Title"] = "Quest Timers"
L["Remote Quests Minion Title"] = "Remote Quests"
L["Scenario Tracker Title"] = "Scenario Tracker"

-- Notifications
L["Quest failed: "] = true
L["Quest completed: "] = true

-- Keybinding tags
L["Toggle Minion"] = true 

-- Outline types
L["None"] = true
L["Outline"] = true
L["Thick Outline"] = true

-- Quest Title Colour Options
L["Custom"] = true
L["Level"] = true
L["Completion"] = true
L["Done/Undone"] = true

-- Objective Colour Options
-- "Custom" See Above
-- "Done/Undone" See Above
-- "Completion" See Above

-- Notification Colour Options
-- "Custom" See Above
-- "Completion" See Above

-- Auto Hide Options
L["Do Nothing"] = true
L["Hide"] = true
L["Show"] = true

-- Quest Tag lengths
-- L["None"] See Above
L["Short"] = true
L["Full"] = true

-- Show/Hide Popup strings
L["Show All"] = true
L["Hide All"] = true
L["Show/Hide Quests"] = true

-- Expand/Collapse Popup strings
L["Expand/Collapse Zones"] = true
L["Collapse All"] = true
L["Expand All"] = true

-- Bag checking
L["You picked up a quest starting item: "] = true
L["picked up a quest starting item: "] = true

-- Help Tooltip
L["You can disable help tooltips in general settings"] = true

-- Help Tooltip - Quest Minion Anchor
L["Quest Minion Anchor"] = true
L["Drag this to move the Quest minion when it is unlocked.\n"] = true
L["Displays # of quests you have in your log and the max limit\n"] = true
L["Displays # of daily quests you have done today of the max limit\n"] = true

-- Help Tooltip - Quest Timer Minion Anchor
L["Quest Timer Minion Anchor"] = true
L["Drag this to move the Quest Timer minion when it is unlocked.\n"] = true

-- Help Tooltip - Remote Quests Minion Anchor
L["Remote Quests Minion Anchor"] = true
L["Drag this to move the Remote Quests minion when it is unlocked.\n"] = true

-- Help Tooltip - Achievement Minion Anchor
L["Achievement Minion Anchor"] = true
L["Drag this to move the Achievement minion when it is unlocked.\n"] = true

-- Help Tooltip - Scenario Minion Anchor
L["Scenario Quests Minion Anchor"] = true
L["Drag this to move the Scenario Quests minion when it is unlocked.\n"] = true

-- Help Tooltip - Show All quests button
L["Show all quests button"] = true
L["Enable to show all hidden quests"] = true

-- Help Tooltip - Zone Header
L["Zone Header"] = true
L["Click to collapse/expand zone"] = true
L["Right-click to show hidden quests toggle dropdown menu\n"] = true
L["Alt Right-click to show zone collapse/expand dropdown menu\n"] = true


---------------------------OPTIONS---------------------------

-- General
L["General Options"] = true

	-- HideAll
	L["Hide All Sorha Quest Log"] = true
	L["Hides all of Sorha Quest Log"] = true
	
	-- ShowAnchorsToggle
	L["Show minion anchors"] = true
	L["Shows the anchors for minions to make them easier to move"] = true
	
	-- ShowHelpTooltipsToggle
	L["Show helpful tooltips"] = true
	L["Shows helpful tooltips for people learning the addon"] = true
	
	-- HeaderBlizzardFrameSettings
	L["Blizzard Frame Settings"] = true

		--HideBlizzardTrackerToggle
		L["Hide the default quest tracker"] = true
		L["Hides blizzards quest tracker.. which is also used for Achievement tracking"] = true
		
	-- HeaderAutoHide
	L["Auto Hide/Showing"] = true
		
		-- OnInstanceAutoHideSelect
		L["When entering a Dungeon"] = true
		L["What to do when entering a Dungeon"] = true
		
		-- OnRaidAutoHideSelect
		L["When entering a Raid"] = true
		L["What to do when entering a Raid"] = true

		-- OnArenaAutoHideSelect
		L["When entering an Arena"] = true
		L["What to do when entering an Arena"] = true
		
		-- OnBattlegroundAutoHideSelect
		L["When entering a Battleground"] = true
		L["What to do when entering a Battleground"] = true
		
		-- OnNormalAutoHideSelect
		L["When entering normal world"] = true
		L["What to do when entering an area that is not an Arena, Battleground, Dungeon or Raid"] = true
		
		-- OnEnterCombatAutoHideSelect
		L["When entering combat"] = true
		L["What to do when entering combat"] = true
		
		-- OnEnterPetBattleAutoHideSelect
		L["When leaving combat"] = true
		L["What to do when leaving combat"] = true

		-- OnEnterPetBattle
		L["When entering pet battle"] = true
		L["What to do when entering a pet battle"] = true
		
		-- OnLeavePetBattleAutoHideSelect
		L["When leaving pet battle"] = true
		L["What to do when leaving a pet battle"] = true
		
		
		
-- QuestMinion
L["Quest Minion"] = true

	-- MainHide
	L["Hide Minion"] = "Disable Quest Minion"
	L["Hides/Shows the Main Frame"] = "Enables\Disables display of the Quest Minion"

	-- MainLock
	L["Lock Frame"] = "Lock Minion"
	L["Unlocks/Locks the Main Frame"] = true
	
	-- HeaderMainFrame
	L["Main Frame Settings"] = true
	
		-- MainWidth
		L["Width"] = true
		L["Controls the width of the main window."] = true
		
		-- Reset
		L["Reset Main Frame"] = true
		L["Resets Main Frame position"] = true
							
	-- HeaderMiscSettings
	L["Misc. Settings"] = true

		-- ShowNumberQuestsToggle
		L["Show number of quests"] = "Show # of Quests"
		L["Shows/Hides the number of quests"] = true
		
		-- ShowNumberOfDailyQuestsToggle
		L["Show # of Dailys"] = true
		L["Shows/Hides the number of daily quests completed"] = true
		
		--CollapseToLeftToggle
		L["Autoshrink to left"] = true
		L["Shrinks the width down when the length of current quests is less then the max width\nNote: Doesn't work well with quests that wordwrap"] = true

		-- GrowUpwardsToggle
		L["Grow Upwards"] = true
		L["Minions grows upwards from the anchor"] = true
		
		-- ConfirmQuestAbandonsToggle
		L["Require confirmation when abandoning a Quest"] = true
		L["Shows the confirm box when you try to abandon a quest"] = true
		
		-- AutoTrackQuests
		L["Automatically track quests"] = "Automatically track quests - Requires reloadui for now"
		L["Same as blizzard setting. Tracked quests are shown quests when the ability to hide quests is on."] = true		
		
		-- AutoTrackQuestsWhenObjectiveupdate
		L["Automatically track quests when objectives update"] = true
		L["Same as blizzard setting. Tracked quests are shown quests when the ability to hide quests is on."] = true
				
		-- HideMinionIfNoTrackedQuestsToggle
		L["Hide minion when not tracking any quests"] = true
		L["Doesn't display the minion when quests are not being tracked. Does not HIDE the minion"] = true

		-- HeaderTitleFont
		L["Title Font Settings"] = true	
		
			-- QuestMinionTitleFontSelect
			L["Font"] = true
			L["The font that the minion title will use"] = true
			
			-- QuestMinionTitleFontOutlineSelect
			L["Font Outline"] = true
			L["The outline that the minion title will use"] = true
			
			-- QuestMinionTitleFontSizeSelect
			L["Font Size"] = true
			L["Controls the font size of the minion title."] = true
			
			-- QuestMinionTitleFontShadowedToggle
			-- L["Shadow Text"] As where-ever
			-- L["Shows/Hides text shadowing"] As where-ever

	-- HeaderItemButtons
	L["Item Button Settings"] = "Tooltips and Item Button Settings"

		-- ShowItemButtonsToggle
		L["Show quest item buttons"] = "Show Item Buttons"
		L["Shows/Hides the quest item buttons"] = true
		
		-- ItemsAndTooltipsRightToggle
		L["Display items and tooltips on right"] = "Move to right"
		L["Moves items and tooltips to the right"] = true	
		
		-- IndentItemButtonsToggle
		L["Indent item buttons inside tracker"] = true
		L["Indents the item buttons into the quest tracker so they are flush with zone headers"] = true

		-- IndentItemButtonQuestsOnlyToggle
		L["Indent only quests with item buttons"] = true
		L["Only indents a quest if the quest has an item button"] = true
		
		-- IndentItemButtonsToggle
		L["Hide Item Buttons for completed quests"] = true
		L["Hides the quests item button once the quest is complete"] = true
		
		-- ItemButtonsSizeSlider
		L["Item Button Size"] = true
		L["Controls the size of the Item Buttons."] = true
		
		
	-- QuestOptions
	L["Quest Options"] = "Zone/Quest Options"
	
		-- DisplaySettingsHeader
		L["Display Settings"] = true

			-- AllowHiddenQuestsToggle
			L["Allow quests to be hidden"] = "Allow hidden quests"
			L["Allows quests to be hidden and enables the show/hide button"] = "Allows quests to be hidden and unhidden by rightclicking the quest. Also enables the show/hide button"
			
			-- AllowHiddenHeadersToggle
			L["Zone headers hide when all contained quests are hidden"] = "Hide zone headers with only hidden quests"
			L["Makes zone headers hide when all contained quests are hidden"] = true
			
			-- AllowHiddenCountOnZonesToggle
			L["Display count of hidden quest in each zone"] = "Display zones hidden quest count"
			L["Displays a count of the hidden quests in each zone on the zone header"] = true
			
			-- ShowQuestLevelsToggle
			L["Display level in Quest Title"] = true
			L["Displays the level of the quest in the title"] = true
			
			-- QuestTagsLengthSelect
			L["Quest Tag Length:"] = true
			L["The length of the quest tags (d, p, g5, ELITE etc)"] = true
			
		-- HeaderZoneHeaders
		L["Zone Header Settings"] = true

			-- ExpandOnEnterToggle
			L["Auto expand zones on enter"] = "Auto Expand on Enter"
			L["Automatically expands zone headers when you enter the zone"] = true
									
			-- CollapseOnLeaveToggle
			L["Auto collapse zones on exit"] = "Auto Collapse on Exit"
			L["Automatically collapses zone headers when you exit the zone"] = true

			-- HeaderFontSelect
			L["Header Font"] = true
			L["The font that the zone headers will use"] = true
			
			-- HeaderFontOutlineSelect
			L["Header Font Outline"] = true
			L["The outline that the zone headers will use"] = true

			-- HeaderFontSize
			L["Header Font Size"] = true
			L["Controls the font size of the header label."] = true
			
			-- HeaderFontShadowedToggle
			L["Shadow Text"] = true
			L["Shows/Hides text shadowing"] = true
			
			-- HideZoneHeadersToggle
			L["Hide Zone Headers"] = true
			L["Hides all zone headers and just displays quests. Note: Does not expand zone headers for you"] = true
				
		-- HeaderQuests
		L["Quest Settings"] = true
								
			-- OpenFullQuestLogToggle
			L["Left-click opens full Quest Log panel"] = true
			L["Open the full quest log when clicking a quest.\nWhen disabled opens only the quest details panel for quests which are not completed remote quests.\n|cffffff78Alt-click always opens full log panel. |r"] = true
		
			-- HideCompletedQuestsToggle
			L["Hide Completed quests/goto Quests"] = true
			L["Automatically hides completed quests on completion. Also hides goto quests"] = true
		
			-- QuestFontSelect
			L["Quest Font"] = true
			L["The font that the quest titles will use"] = true
			
			-- QuestFontOutlineSelect
			L["Quest Font Outline"] = true
			L["The outline that the quest titles will use"] = true
			
			-- QuestFontSize
			L["Quest Font Size"] = true
			L["Controls the font size of the quest info."] = true
			
			-- QuestFontShadowedToggle
			-- L["Shadow Text"]  SEE ABOVE
			-- L["Shows/Hides text shadowing"]  SEE ABOVE
			
			-- QuestTitleIndent
			L["Quest Text Indent"] = true
			L["Controls the level of indentation for the quest text"] = true
			
			L["Padding After Quest"] = true
			L["The amount of extra padding after a quest before the next text."] = true
							
		-- HeaderObjectives
		L["Objective Settings"] = true
		
			-- HideCompletedObjectivesToggle
			L["Hide completed objectives"] = true
			L["Shows/Hides completed objectives"] = true

			--ShowDescWhenNoObjectivesToggle
			L["Display quest description if not objectives"] = "Display quest description when there is no objectives"
			L["Displays a quests description if there are no objectives available"] = true
			
			-- ObjectiveFontSelect
			L["Objective Font"] = true
			L["The font that the quest objectives will use"] = true
			
			-- ObjectiveFontOutlineSelect
			L["Objective Font Outline"] = true
			L["The outline that the quest objectives will use"] = true
			
			-- ObjectiveFontSize
			L["Objective Font Size"] = true
			L["Controls the font size of the quest objectives"] = true
			
			-- ObjectiveFontShadowedToggle
			-- L["Shadow Text"]  SEE ABOVE
			-- L["Shows/Hides text shadowing"]  SEE ABOVE
			
			-- ObjectivesIndent
			L["Objective Text Indent"] = true
			L["Controls the level of indentation for the Objective text"] = true
		
	-- ColourOptions
	L["Colour Options"] = true

		-- HeaderColourSettings
		L["Colour Settings"] = true
			
			-- QuestLevelColouringSelect
			L["Colour quest levels by:"] = true
			L["The setting by which the colour of quest levels are determined"] = true
			
			-- QuestTitleColouringSelect
			L["Colour quest titles by:"] = true
			L["The setting by which the colour of quest titles is determined"] = true
			
			-- ObjectiveStatusColouringSelect
			L["Colour objective status text by:"] = true
			L["The setting by which the colour of objective statuses is determined"] = true

			-- ObjectiveDescriptionColouringSelect
			L["Colour objective title text by:"] = true
			L["The setting by which the colour of objective title is determined"] = true

		-- HeaderMainColours
		L["Main Colours"] = true


		
			-- HeaderColour
			L["Zone Header Colour"] = "Zone Header"
			L["Sets the color for the header of each zone"] = true
			
			--NoObjectivesColour
			L["No objectives description colour"] = "Description text"
			L["Sets the color for the description displayed when there is no quest objectives"] = true
			
			-- QuestTitleColour
			L["Quest titles"] = true
			L["Sets the color for the quest titles if colouring by level is off"] = "Sets the color for the quest titles if custom colouring is on"

			-- QuestLevelColour
			L["Quest levels"] = true
			L["Sets the color for the quest levels if custom colouring is on"] = true
						
			-- ObjectiveTitleColourPicker
			L["Objective title colour"] = true
			L["Sets the custom color for objectives titles"] = true
				
			-- ObjectiveStatusColourPicker
			L["Objective status colour"] = true
			L["Sets the custom color for objectives statuses"] = true

			-- QuestStatusFailedColourPicker
			L["Quest failed tag"] = true
			L["Sets the color for the quest failed tag"] = true
			
			-- QuestStatusDoneColourPicker
			L["Quest done tag"] = true
			L["Sets the color for the quest done tag"] = true
			
			-- QuestStatusGotoColourPicker
			L["Quest goto Tag"] = true
			L["Sets the color for the quest goto tag"] = true
			
			-- QuestMinionTitleColourPicker
			L["Minion Title Text"] = true
			L["Sets the color for the minion title text"] = true
		
			--ObjectiveTooltipTextColourColourPicker
			L["Objective Tooltip Text"] = true
			L["Sets the color for the objective text in the quests tooltip"] = true
		
		
	-- QuestTimer
	L["Quest Timer"] = true
		
		-- ShowQuestTimerFrameToggle
		L["Show Quest Timer Frame"] = "Enable Quest Timer Minion"
		L["Shows a quest timer frame since the blizzard one hides with the default watcher"] = true
		
		-- TimerWindowLockedToggle
		L["Lock Quest Timer Frame"] = "Lock Quest Timer"
		L["Locks the quest timer frame"] = true
		
		-- HideTitleWhenNoTrackingToggle
		L["Hide title when you have no timers"] = true
		L["Hide the Quest Timer frames title when you have no timers running"] = true
		
		-- ShowTitleToggle
		L["Show Quest Timer Frame Title"] = true
		L["Shows the Quest Timer Frame title"] = true
					
		-- ShowBorderToggle
		L["Enable border"] = true
		L["Shows a border when the minion is visible, uses the Quest Minion colouring"] = true

					
	-- RemoteQuests
	L["Remote Quests"] = true

		-- ShowRemoteQuestMinionToggle
		L["Show Remote Quest Minion"] = "Enable Remote Quest Minion"
		L["Shows a minion for displaying remote quests since hiding the blizzard watcher hides these"] = true

		-- MinionLockedToggle
		L["Lock Remote Quests Minion"] = true
		L["Locks the remote quests minion"] = true

		-- ShowTitleToggle
		L["Show Remote Quests Minion title"] = true
		L["Shows the title for the Remote Quests Minion"] = true
		
		-- HideTitleWhenNoRemoteQuestsToggle
		L["Hide title when you have no remote quests"] = true
		L["Hide the title when you have no current remote quests"] = true

		-- ShowBorderToggle
		-- L["Enable border"] SEE ABOVE
		-- L["Shows a border when the minion is visible, uses the Quest Minion colouring"] SEE ABOVE
		
		-- RemoteMinionButtonSizeSlider
		L["Minion Scale"] = true
		L["Controls the size of the Minion"] = true


	
-- AchievementMinionOptions
L["Achievement Options"] = "Achievement Minion"

	-- ShowAchievementMinionFrameToggle
	L["Show Minion"] = "Enable Achievement Minion"
	L["Shows the Achievement Minion"] = "Enables\Disables display of the Achievement Minion"

	-- AchievementMinionLockedToggle
	L["Lock Minion"] = true
	L["Locks the Achievement Minion"] = true

	-- DisplaySettingsHeader
	L["Achievement Minion Settings"] = true
		
		-- AchievementMinionWidth
		-- "Width" See Above
		L["Controls the width of the minion"] = true
		
		-- AchievementMinionReset
		L["Reset Minion Position"] = true
		L["Resets Achievement Minions position"] = true

	-- HeaderMisc
	L["Misc Settings"] = true

		-- ShowTitleToggle
		L["Show Minion Title"] = true
		L["Shows the Achievement Minions title"] = true

		-- GrowUpwardsToggle
		-- L["Grow Upwards"] SEE ABOVE
		-- L["Minions grows upwards from the anchor"] SEE ABOVE
		
		-- HideTitleWhenNoTrackingToggle
		L["Hide title when not tracking"] = true
		L["Hide the Achievement Minions title when not tracking"] = true

		-- CollapseToLeftToggle
		L["Autoshrink to left"] = true
		L["Shrinks the width down when the length of current achivements is less then the max width\nNote: Doesn't work well with achivements that wordwrap"] = "Shrinks the width down when the length of current achievements is less then the max width\nNote: Doesn't work well with achievements that wordwrap"
		
		-- MoveTooltipsRightToggle
		L["Tooltips on right"] = true
		L["Moves the tooltips to the right"] = true
			
		-- UseStatusBarsToggle
		L["Use Bars"] = true
		L["Uses status bars for achivements with a quanity"] = "Uses status bars for achievements with a quanity"		
		
		-- StatusBarTextureSelect
		L["Bar Texture"] = true
		L["The texture the status bars for achievement progress use"] = true
		
		-- MaxNumTasks
		L["Tasks # Cap (0 = All)"] = true
		L["# Tasks shown per Achievement. Set to 0 to display all tasks"] = true
		
		-- HeaderTitleFont
		L["Minion Title Font Settings"] = true
		
			-- AchievementMinionTitleFontSelect
			L["Font"] = true
			L["The font that the minion title will use"] = true

			-- AchievementMinionTitleFontOutlineSelect
			L["Font Outline"] = true
			L["The outline that the minion title will use"] = true

			-- AchievementMinionTitleFontSizeSelect
			L["Font Size"] = true
			L["Controls the font size of the minion title."] = true

			-- AchievementMinionTitleFontShadowedToggle
			L["Shadow Text"] = true
			L["Shows/Hides text shadowing"] = true
		
		
	-- HeaderFonts
	L["Font Settings"] = true
						
		-- AchievementTitleFontSelect
		L["Title Font"] = true
		L["The font that the achievement titles will use"] = true
	
		-- AchievementTitleFontOutlineSelect
		L["Title Font Outline"] = true
		L["The outline that the achievement titles will use"] = true

		-- AchievementTitleFontSizeSize
		L["Title Font Size"] = true
		L["Controls the font size of the achievement title"] = true
		
		-- AchievementTitleFontShadowedToggle
		-- L["Shadow Text"] See Above
		-- L["Shows/Hides text shadowing"] See Above
		
		-- AchievementObjectiveFontSelect
		L["Task Font"] = true
		L["The font that the achievement tasks will use"] = true
		
		-- AchievementObjectiveFontOutlineSelect
		L["Task Font Outline"] = true
		L["The outline that the achievement tasks will use"] = true

		-- AchievementObjectiveFontSizeSize
		L["Task Font Size"] = true
		L["Controls the font size of the achievement task"] = true
		
		-- AchievementObjectiveFontShadowedToggle
		-- L["Shadow Text"] See Above
		-- L["Shows/Hides text shadowing"] See Above
							
	-- ColourOptions
	-- See Above

		-- HeaderColourSettings
		-- See Above
		
			-- AchievementMinionTitleColour
			L["Achievement Minion Title"] = true
			L["Sets the color for Achievement Minion Titles"] = true
		
			-- AchievementTitleColour
			L["Achievement Titles"] = true
			L["Sets the color for Achievement Titles"] = true
			
			-- AchievementObjectiveColour
			L["Achievement Task"] = true
			L["Sets the color for Achievement Objectives"] = true

			-- AchievementStatusBarFillColour
			L["Bar Fill Colour"] = true
			L["Sets the color for the completed part of the achievement status bars"] = true

			-- AchievementStatusBarBackColour
			L["Bar Back Colour"] = true
			L["Sets the color for the un-completed part of the achievement status bars"] = true
			
			-- AchievementMinionBackGroundColour
			L["Background Colour"] = true
			L["Sets the color of the minions background"] = true
				
			-- AchievementMinionBorderColour
			L["Border Colour"] = true
			L["Sets the color of the minions border"] = true

-- NotificationOptions
L["Notification Settings"] = true

	-- NotificationSettingsHeader
	L["Text Notification Settings"] = "Blizzard Settings"

		-- SuppressBlizzardNotificationsToggle
		L["Suppress blizzard notification messages"] = true
		L["Suppresses the notification messages sent by blizzard to the UIErrors Frame for progress updates"] = true

		-- LibSinkHeader
		L["LibSink Options"] = true
			
			-- LibSinkObjectivesSmallHeader
			L["Objective Notifications"] = true
			
				-- LibSinkObjectiveNotificationsToggle
				L["Use for Objective notification messages"] = true
				L["Displays objective notification messages using LibSink"] = true
				
				-- DisplayQuestOnObjectiveNotificationsToggle
				L["Display Quest Name"] = true
				L["Adds the quest name to objective notification messages"] = true
				
		-- LibSinkQuestsSmallHeader
		L["Quest Notifications"] = true
							
			-- ShowQuestCompletesAndFailsToggle
			L["Output Complete and Failed messages for quests"] = "Use for Quest notification messages"
			L["Displays '<Quest Title> (Complete)' etc messages once you finish all objectives"] = "Displays 'Quest Complete: <Quest Title>' etc messages once you finish all objectives"
			
			-- ShowMessageOnPickingUpQuestItemToggle
			L["Show message when picking up an item that starts a quest"] = "Use to show message when picking up a quest starting item"
			L["Displays a message through LibSink when you pick up an item that starts a quest"] = true
				
		-- LibSinkColourSmallHeader
		-- L["Colour Settings"] SEE ABOVE
							
			-- NotificationsColourSelect
			L["Lib Sink Colour by:"] = true
			L["The setting by which the colour of notification messages are determined"] = true
			
			-- NotificationsColour
			L["Notifications"] = "Default LibSink colour"
			L["Sets the color for notifications"] = "Sets the color for LibSink notifications that do not use completion colouring"
		
		
	-- SoundSettingsHeader
	L["Sound Settings"] = true

		-- ObjectiveDoneSoundSelect
		L["Objective Completion Sound"] = true
		L["The sound played when you complete a quests objective"] = true
	
		-- QuestDoneSoundSelect
		L["Quest Completion Sound"] = true
		L["The sound played when you complete a quest (Finish all objectives)"] = true
	
		-- QuestItemFoundSoundSelect
		L["Quest Starting Item Picked Up"] = true
		L["The sound played when you pickup an item that starts a quest"] = true
	
		
-- ColourOptions
-- "Colour Settings" See Above

	-- InfoTextColour
	L["Info Text"] = true
	L["Sets the color of the info text (Title bar, # of quests hidden etc)"] = true
			
	-- HeaderGradualColours
	L["Gradual objective Colours"] = "Completeness Colours" 
	
		-- Objective00PlusColour
		L["0% Complete objective colour"] = "0-24% completed"
		L["Sets the color for objectives that are above 0% complete"] = true
		
		-- Objective25PlusColour
		L["25% Complete objective colour"] = "25-49% completed"
		L["Sets the color for objectives that are above 25% complete"] = true

		-- Objective50PlusColour
		L["50% Complete objective colour"] = "50-74% completed"
		L["Sets the color for objectives that are above 50% complete"] = true

		-- Objective75PlusColour
		L["75% Complete objective colour"] = "74-99% completed"
		L["Sets the color for objectives that are above 75% complete"] = true
		
		-- DoneObjectiveColour
		L["Complete objective colour"] = "100% completed"
		L["Sets the color for the complete objectives"] = true