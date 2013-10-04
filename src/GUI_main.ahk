/*
    SFSO - Stars Filtered SNG Opener
    Copyright (C) 2008, 2009  Everlong@2p2 Code assembled from misc sources, thanks to _dave_, chris228, finnisher
    Copyright (C) 2009, 2011-2013  Max1mums
    Copyright (C) 2013  GreaseFire

    Official thread for discussion, questions and new releases:
    http://forumserver.twoplustwo.com/168/free-software/ahk-script-stars-filtered-sng-opener-234749/

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/* 	AHK_L 1.1.11.1 has a bug regarding UpDown controls:
	 Gui, Add, UpDown, vMyVar, %MyVar%	will ignore %MyVar% and set its buddy Edit to the default value
	AHK_L 1.1.13.0 shows the expected behaviour, but doesn't mention it in the changelog
*/
BuildGui:
Gui, color, white
Gui, font, cOlive , Segoe UI

Gui, add, Text,		y+15 Section																	, Register every (sec):
Gui, add, Text, 																					, No of SNG:s to keep open:
Gui, add, CheckBox,	y+14		vOverrideScrlDwn	gScrlDwnOnOff			, Override available games:
Gui, add, CheckBox,	y+14		vTotalLimitEnabled	gTotalLimitOnOff		, Limit total SNG:s to:
Gui, add, CheckBox,	y+14		vLimitTimeEnabled	gLimitTimeOnOff			, Limit total time to (min):

Gui, add, Edit,		ys-3	w40	vRegisterInterval				Right	Number	Limit3
Gui, add, UpDown, 					gUpDownRegisterInterval		Range5-180				
Gui, add, Edit,				wp	vKeepOpen						Right	Number	Limit3	
Gui, add, UpDown, 					gEnableDefaultButtons		Range1-30				
Gui, add, Edit,				wp	vAvailableGames					Right	Number	Limit3	
Gui, add, UpDown, 					gEnableDefaultButtons		Range1-30				
Gui, add, Edit,				wp	vTotalLimit						Right	Number	Limit3	
Gui, add, UpDown,					gEnableDefaultButtons		Range1-300				
Gui, add, Edit,				wp	vLimitTime						Right	Number	Limit3	
Gui, add, UpDown,					gUpDownLimitTime			Range10-360				

Gui, add, DropDownList, xs Section w130 vselectedFilter	gChangeActiveFilter	Disabled
Gui, add, Button, ys-1 x+2				vButtonAdd		gButtonAddFilter	Disabled		, Edit
Gui, add, Button, ys-1 x+2				vButtonDelete	gButtonDeleteFilter	Disabled		, Delete
Gui, add, Button, xs Section			vButtonSafe		gButtonSafeDefault	Disabled		, Save as Default
Gui, add, Button, ys x+2				vButtonLoad		gButtonLoadDefault	Disabled		, Load Default

Gui, add, GroupBox, xs Section w90 h120 Disabled, Remaining
Gui, Add, Text, xp+20 yp+20													, Time:
Gui, Add, Edit, 			w50		vInfoTimeLeft		Center	Disabled
Gui, Add, Text,																, Games:
Gui, Add, Edit,				w50		vInfoGamesLeft		Center	Disabled

Gui, add, GroupBox, ys w90 h120 Disabled, Registered
Gui, Add, Text, xp+20 yp+20													, Session:
Gui, Add, Edit,				w50		vInfoRegSession		Center	Disabled
Gui, Add, Text,																, Total:
Gui, Add, Edit,				w50		vInfoRegTotal		Center	Disabled


;~ Gui, Add, Text, xs y+20	Section													, Remaining:
;~ Gui, Add, Edit, w30 Hidden ; placeholder
;~ Gui, Add, Text, 																, Registered:
;~ Gui, Add, Text, ys	x+30														, Time:
;~ Gui, Add, Edit, 			w50		vInfoTimeLeft		Center	Disabled
;~ Gui, Add, Text, 																, Session:
;~ Gui, Add, Edit,				w30		vInfoRegSession		Right	Disabled
;~ Gui, Add, Text, ys																, Games:
;~ Gui, Add, Edit,				w30		vInfoGamesLeft		Right	Disabled
;~ Gui, Add, Text,																	, Total:
;~ Gui, Add, Edit,				w30		vInfoRegTotal		Right	Disabled

Gui, add, Button, xs y+20	Section 		gRun			, Start session
Gui, Add, Button, 				wp				Disabled	, Show Lobby
Gui, Add, Button, ys							Disabled	, Pause
Gui, Add, Button, 											, Donate
Gui, Add, Button, ys							Disabled	, Resume
Gui, Add, Button, 											, Options

Gui, add, statusBar
SB_SetParts(160)

Gui, show, AutoSize x%GuiScreenPosX% y%GuiScreenPosY%, SFSO %sfsoVersion%
Gui, +HwndmainGuiId
resetStatus()
OnMessage(0x232,"WM_EXITSIZEMOVE")	; called after the GUI got moved
gosub, ButtonLoadDefault
gosub, LimitTimeOnOff
gosub, TotalLimitOnOff

oldRegisterInterval := RegisterInterval
oldLimitTime := LimitTime
oldCloseInterv := CloseInterv

gosub, setupFilterManager
Return

LimitTimeOnOff:
if (A_GuiEvent == "Normal")
{
	Gui, Submit, NoHide
	GuiControl, Enabled%LimitTimeEnabled%	, LimitTime
	gosub, enableDefaultButtons
}
return

TotalLimitOnOff:
if (A_GuiEvent == "Normal")
{
	Gui, Submit, NoHide
	GuiControl, Enabled%TotalLimitEnabled%	, TotalLimit
	gosub, enableDefaultButtons
}
return

ScrlDwnOnOff:
if (A_GuiEvent == "Normal")
{
	Gui, Submit, NoHide
	GuiControl, Enabled%OverrideScrlDwn%	, AvailableGames
	gosub, enableDefaultButtons
}
return

UpDownRegisterInterval:
if (A_GuiEvent == "Normal")
{
	upDownChangeBy("RegisterInterval", 5)
	gosub, enableDefaultButtons
}
return

UpDownLimitTime:
if (A_GuiEvent == "Normal")
{
	upDownChangeBy("LimitTime", 10)
	gosub, enableDefaultButtons
}
return

ButtonAddFilter:
if showAddFilterGUI()
	gosub, enableDefaultButtons
return

ButtonDeleteFilter:
MsgBox, 1, Delete Filter, Press OK to delete filter`n   "%selectedFilter%"
IfMsgBox, OK
{
	fileName := getFileName(selectedFilter)
	FileDelete, %sfsoSettingsFolder%\Filters\%fileName%.ini
	availableFilters := getFilterList()
	filterList := ""
	for i, filter in availableFilters
		filterList .= "|" . filter
	;~ StringReplace, filterList, filterList, |,
	GuiControl, , selectedFilter	, %filterList%
}
return

ChangeActiveFilter:
if (A_GuiEvent == "Normal") ; only triggers on actual user input
{
	Gui, Submit, NoHide
	stopRegistering := true
	setActiveFilter(loadFilter(selectedFilter))
	gosub, enableDefaultButtons
}
return

enableFilterControls:
GuiControl, Enable, ButtonDelete
GuiControl, Enable, selectedFilter
GuiControl, Enable, ButtonAdd
return

enableDefaultButtons:
GuiControl, Enable, ButtonSafe
GuiControl, Enable, ButtonLoad
return

disableDefaultButtons:
GuiControl, Disable, ButtonSafe
GuiControl, Disable, ButtonLoad
return

ButtonSafeDefault:
Gui, Submit, NoHide
IniWrite, %RegisterInterval%	, %sfsoSettingsFolder%\SFSO.ini, Settings, RegisterInterval
IniWrite, %KeepOpen%			, %sfsoSettingsFolder%\SFSO.ini, Settings, KeepOpen
IniWrite, %OverrideScrlDwn%			, %sfsoSettingsFolder%\SFSO.ini, Settings, OverrideScrlDwn
IniWrite, %AvailableGames%			, %sfsoSettingsFolder%\SFSO.ini, Settings, AvailableGames
IniWrite, %TotalLimit%			, %sfsoSettingsFolder%\SFSO.ini, Settings, TotalLimit
IniWrite, %TotalLimitEnabled%	, %sfsoSettingsFolder%\SFSO.ini, Settings, TotalLimitEnabled
IniWrite, %LimitTime%			, %sfsoSettingsFolder%\SFSO.ini, Settings, LimitTime
IniWrite, %LimitTimeEnabled%	, %sfsoSettingsFolder%\SFSO.ini, Settings, LimitTimeEnabled
IniWrite, %selectedFilter%		, %sfsoSettingsFolder%\SFSO.ini, Settings, selectedFilter
gosub, disableDefaultButtons
return

ButtonLoadDefault:
IniRead, RegisterInterval	, %sfsoSettingsFolder%\SFSO.ini, Settings, RegisterInterval		, 20
IniRead, KeepOpen			, %sfsoSettingsFolder%\SFSO.ini, Settings, KeepOpen				, 3
IniRead, OverrideScrlDwn			, %sfsoSettingsFolder%\SFSO.ini, Settings, OverrideScrlDwn				, 0
IniRead, TotalLimit			, %sfsoSettingsFolder%\SFSO.ini, Settings, TotalLimit			, 4
IniRead, AvailableGames			, %sfsoSettingsFolder%\SFSO.ini, Settings, AvailableGames			, 4
IniRead, TotalLimit			, %sfsoSettingsFolder%\SFSO.ini, Settings, TotalLimit			, 4
IniRead, TotalLimitEnabled	, %sfsoSettingsFolder%\SFSO.ini, Settings, TotalLimitEnabled	, 1
IniRead, LimitTime			, %sfsoSettingsFolder%\SFSO.ini, Settings, LimitTime			, 30
IniRead, LimitTimeEnabled	, %sfsoSettingsFolder%\SFSO.ini, Settings, LimitTimeEnabled		, 0
IniRead, selectedFilter		, %sfsoSettingsFolder%\SFSO.ini, Settings, selectedFilter		, New Filter
availableFilters := getFilterList()
filterList := ""
for i, filter in availableFilters
{
	filterList .= "|" . filter
	if (filter == selectedFilter)
		filterList .= "||"
}
StringReplace, filterList, filterList, |||, ||
GuiControl, , selectedFilter	, %filterList%
GuiControl, , RegisterInterval	, %RegisterInterval%
GuiControl, , KeepOpen			, %KeepOpen%
GuiControl, , TotalLimit		, %TotalLimit%
GuiControl, , TotalLimitEnabled	, %TotalLimitEnabled%	
GuiControl, , LimitTime			, %LimitTime%		
GuiControl, , LimitTimeEnabled	, %LimitTimeEnabled%
GuiControl, Enabled%TotalLimitEnabled%	, TotalLimit
GuiControl, Enabled%LimitTimeEnabled%	, LimitTime
GuiControl, Enabled%OverrideScrlDwn%	, AvailableGames
gosub, disableDefaultButtons
return

ButtonDonate:
donation()
Return

ButtonShowLobby:
WinMove, %PS_LOBBY% ahk_class %PS_CLASS%, , %psLobbyPosX%, %psLobbyPosY%
GuiControl, Disable, Show Lobby
return

ButtonOptions:
gosub, showOptions
return

; called after the GUI window has been moved
; see http://msdn.microsoft.com/en-us/library/windows/desktop/ms632623(v=vs.85).aspx
WM_EXITSIZEMOVE()
{
	global
	IfWinExist, ahk_id %mainGuiId%	; WM_EXITSIZEMOVE gets called at least once before the main GUI is shown at which point WinGetPos would fail
		WinGetPos, GuiScreenPosX, GuiScreenPosY, , , ahk_id %mainGuiId%
	return 0
}

GuiClose:
GuiControlGet, lobbyRestoreEnabled, Enabled
if (minLob and lobbyRestoreEnabled)
	gosub, buttonshowLobby
Gui, Submit
Gosub, saveSettings
ExitApp

; changes the control associated with editControlVarName by the amount given
upDownChangeBy(editControlVarName, amount)
{
	global
	local currentValue
	GuiControlGet, currentValue, , %editControlVarName%
	if (currentValue > old%editControlVarName%)
		currentValue += amount
	currentValue -= mod(currentValue , amount)
	GuiControl, , %editControlVarName%, %currentValue%
	old%editControlVarName% = %currentValue%
}

; updates the info area
; call setStatus() or setStatus(0) to only update the counters
setStatus(statusType=0)
{
	global
	static oldStatus := 0
	local gamesOpen := gamesRunning + gamesWaiting
	local gameStatus := ""
	
	if gamesOpen > 0
	{
		gameStatus := gamesRunning
		if gamesWaiting > 0
			gameStatus .= " +" . gamesWaiting
	}
	gameStatus .=  "`t`t" . gamesOpen
	SB_SetText(gameStatus, 2)

	if (TotalLimitEnabled)
	{
		gamesLeft := TotalLimit - regSofar
		GuiControl, , InfoGamesLeft, %gamesLeft%
	}
	GuiControl, , InfoRegTotal, %gamesFinished%
	GuiControl, , InfoRegSession, %RegSofar%

	if (statusType == 0)
		return
	
	if (statusType == REMAINING_TIME)
		GuiControl, , InfoTimeLeft, %displayedTime%
	if (statusType == USER_INACTIVE)
	{
		SB_SetText("Idle (User inactive)")
		GuiControl, , InfoTimeLeft, %displayedTime%
	}
	if (statusType == MANUAL_PAUSE)
	{
		SB_SetText("Idle (Manually Paused)")
		GuiControl, , InfoTimeLeft, %displayedTime%
	}
	
	if (oldStatus != statusType)
	{
		oldStatus := statusType
		if (statusType == WAITING)
			SB_SetText("Waiting")
		if (statusType == REGISTERING)
			SB_SetText("Registering")
		if (statusType == IDLE)
			SB_SetText("Idle")
		if (statusType == SET_FULL)
			SB_SetText("Waiting (Set Full)")
		if (statusType == NO_GAMES_AVAILABLE)
			SB_SetText("Waiting for available games")
		if (statusType == TOTAL_LIMIT_REACHED)
			SB_SetText("Idle (SNG Limit reached)")
		if (statusType == LOBBY_NOT_FOUND)
			SB_SetText("Idle (Lobby not found)")
		if (statusType == TIME_LIMIT_REACHED)
			SB_SetText("Idle (Time Limit reached)")
		if (statusType == NOT_IN_SNG_LOBBBY)
			SB_SetText("Idle (PS not in SNG Lobby")
		if (statusType == WAITING_FOR_REMATCH)
			SB_SetText("Waiting for rematch decision")
		if (statusType == GAMECOUNT_MISMATCH)
			SB_SetText("Unexpected number of games")
		
		
	}
}

resetStatus()
{
	global gamesFinished
	SB_SetText("Idle")
	SB_SetText("`t`t0", 2)
	GuiControl, , InfoTimeLeft,
	GuiControl, , InfoGamesLeft,
	GuiControl, , InfoRegSession, 0
	GuiControl, , InfoRegTotal, %gamesFinished%
}
