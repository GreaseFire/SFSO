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
Gui, font, cOlive

Gui, add, tab2, 	vMainTab	, General|Advanced Settings


Gui, add, Text,		y+15 Section																, Register every (sec):
Gui, add, Text, 																				, No of SNG:s to keep open:
Gui, add, CheckBox,	y+14		vTotalLimitEnabled	gSpinnersOnOff	Checked%TotalLimitEnabled%	, Limit total SNG:s to:
Gui, add, CheckBox,	y+14		vLimitTimeEnabled	gSpinnersOnOff	Checked%LimitTimeEnabled%	, Limit total time to (min):

Gui, add, Edit,		ys-3	w40	vRegisterInterval			Number	Limit3	, %RegisterInterval%
Gui, add, UpDown, 					gRegisterIntervalUpDown	Range5-180		, %RegisterInterval%
Gui, add, Edit,				wp	vKeepOpen					Number	Limit3	, %keepOpen%
Gui, add, UpDown, 											Range1-30		, %keepOpen%
Gui, add, Edit,				wp	vTotalLimit					Number	Limit3	, %TotalLimit%
Gui, add, UpDown,											Range1-300		, %TotalLimit%
Gui, add, Edit,				wp	vLimitTime					Number	Limit3	, %LimitTime%
Gui, add, UpDown,					gLimitTimeUpDown		Range10-360		, %LimitTime%

; Gui, Add, Button, ys Disabled, TabControlResizeTest

Gui, add, text, xs y+30 		w200	vCdown		cRed
Gui, add, text, 				wp		vRegSofar			, SNG:s registered so far:
Gui, add, text,					wp		vOpenTables			, Tables open/waiting:
Gui, add, text,					wp		vStatus		cRed	, Status: Idle

Gui, add, Button, xs	Section 			gRun			, Submit + Run
Gui, Add, Button, 								Disabled	, Show Lobby
Gui, Add, Button, ys							Disabled	, Pause
Gui, Add, Button, 				wp							, Donate
Gui, Add, Button, ys							Disabled	, Resume


Gui, tab, Advanced

Gui, add, CheckBox,	y+14	Section	vGuardtimerEnabled	gSpinnersOnOff	Checked%GuardtimerEnabled%	, Disable if no user Input (min):
Gui, add, CheckBox,	y+14			vscrldwnEnabled		gSpinnersOnOff	Checked%scrldwnEnabled%		, No. of available Games:
Gui, add, CheckBox,	y+14	r2		vCloseIntervEnabled	gSpinnersOnOff	Checked%CloseIntervEnabled%	, Close lobbies every (sec):`n(manually Close with Win+c)

Gui, add, Edit,		ys-3	w40		vGuardtimer						Number	Limit2				, %Guardtimer%
Gui, add, UpDown, 													Range1-15					, %Guardtimer%
Gui, add, Edit,				wp		vscrldwn						Number	Limit2				, %scrldwn%
Gui, add, UpDown, 													Range1-21					, %scrldwn%
Gui, add, Edit,				wp		vCloseInterv					Number	Limit3				, %CloseInterv%
Gui, add, UpDown, 						gCloseIntervUpDown			Range5-180					, %CloseInterv%

Gui, add, Checkbox, xs y+30			vBatchReg						Checked%BatchReg%			, Register with high frequency`nwhen no tables open/waiting
Gui, add, Checkbox,					vSetReg							Checked%SetReg%				, Register in sets
Gui, add, Checkbox,					vMinLob							Checked%MinLob%				, Move lobby off screen`n(Failsafe: Win+Shift+Home)
Gui, add, Checkbox, 				vReturnFocus					Checked%ReturnFocus%		, Activate open table after registering
Gui, add, Checkbox,					vAutoifFull						Checked%AutoIfFull%			, Register next if full
Gui, add, Checkbox,					vTopReturn						Checked%TopReturn%			, Always start at top of lobby

Gui, add, Checkbox, 		r2		vrequestElevation 				Checked%requestElevation%	, Request Admin Privileges?`n(requires restart)

Gui, add, Button, , Identify PS controls

;Gui, add, statusBar
; TODO: change info area to use statusBar where appropriate


Gui, show, AutoSize x%GuiScreenPosX% y%GuiScreenPosY%, SFSO %sfsoVersion%
Gui, +HwndmainGuiId
goSub, resizeTabControl
goSub, SpinnersOnOff
Return

; tab controls do not automatically get resized on Gui, Show, AutoSize
; this is a manual workaround. Crude, but effective
; parses all controls except the statusbar and the tab control itself
; resizes the tab control using the controls furthest to the right and bottom
resizeTabControl:
WinGet, ControlList, ControlList, ahk_id %mainGuiId%
WinGetPos, , , LeftMost, TopMost, ahk_id %mainGuiId%
rightMost := 0
bottomMost := 0
Loop, Parse, ControlList, `n
{
	if A_LoopField in msctls_statusbar321,SysTabControl321
		continue
	ControlGetPos, X, Y, Width, Height, %A_LoopField%, ahk_id %mainGuiId%
	width += x
	height += y
	if (width > rightMost)
		rightMost := width
	if (height > bottomMost)
		bottomMost := height
}
; TODO this value changes with the font size, maybe even DPI setting
bottomMost -= 20	; subtract the height of the tab controls item list
guiControl, Move, MainTab, w%rightMost% h%bottomMost%
Gui, Show, AutoSize
return

SpinnersOnOff:
Gui, Submit, NoHide
GuiControl, Enabled%TotalLimitEnabled%	, TotalLimit
GuiControl, Enabled%LimitTimeEnabled%	, LimitTime
GuiControl, Enabled%GuardtimerEnabled%	, Guardtimer
GuiControl, Enabled%scrldwnEnabled%		, scrldwn
GuiControl, Enabled%CloseIntervEnabled%	, CloseInterv
return

RegisterIntervalUpDown:
upDownChangeBy("RegisterInterval", 5)
return

LimitTimeUpDown:
upDownChangeBy("LimitTime", 10)
return

CloseIntervUpDown:
upDownChangeBy("CloseInterv", 5)
return

buttonDonate:
donation()
Return

buttonShowLobby:
WinMove, PokerStars Lobby ahk_class #32770, , %psLobbyPosX%, %psLobbyPosY%
GuiControl, Disable, Show Lobby
return

ButtonIdentifyPSControls:
gosub, showIDTool
return

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
	if (old%editControlVarName% == "")
		old%editControlVarName% := currentValue
	if (currentValue > old%editControlVarName%)
		currentValue += amount
	currentValue -= mod(currentValue , amount)
	GuiControl, , %editControlVarName%, %currentValue%
	old%editControlVarName% = %currentValue%
}

; updates the info area
; call setStatus() or setStatus(0) to only update openTables and regSoFar
setStatus(statusType=0)
{
	global
	static oldStatus := 0
	GuiControl, , OpenTables, Tables open/waiting: %OpenTables%
	GuiControl, , RegSofar, SNG:s registered so far: %RegSofar%
	
	if (statusType == 0)
		return
	
	if (statusType == MANUAL_PAUSE)
	{
		GuiControl, , cdown, Manually Paused %displayedTime%
		GuiControl, , Status, Status: Waiting
	}
	if (statusType == REMAINING_TIME)
		GuiControl, , cdown, Running another (mm:ss): %displayedTime%
	if (statusType == USER_INACTIVE)
		GuiControl, , cdown, Stopped  due to inactivity!!! %displayedTime%
	
	if (oldStatus != statusType)
	{
		oldStatus := statusType
		if (statusType == WAITING)
			GuiControl, , Status, Status: Waiting
		if (statusType == REGISTERING)
			GuiControl, , Status, Status: Registering
		if (statusType == IDLE)
			GuiControl, , Status, Status: Idle
		if (statusType == SET_FULL)
			GuiControl, , Status, Status: Set Full waiting
		if (statusType == TOTAL_LIMIT_REACHED)
		{
			GuiControl, , cdown, SNG Total Limit reached
			GuiControl, , Status, Status: Idle
		}
		if (statusType == LOBBY_NOT_FOUND)
			GuiControl, , Status, Status: PokerStars Lobby not found
		if (statusType == TIME_LIMIT_REACHED)
			GuiControl, , cdown, Time Limit reached.
		if (statusType == TIME_LIMIT_OFF)
			GuiControl, , cdown, Time Limit off
	}
}
