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

 v4.1
 - SFSO will now remember its on screen position
 - Added check whether script is running in ANSI mode
 - Added auto detection for pokerstars logfile
 - Request Admin privileges if called for
 - Added tool to identify controls in PS client
 - Settings are now kept in the current users AppData folder

 v4.01
 added: option to atuobuyin if full, hide/show window
 fixed issue with skipping first sng in lobby 

 4.0 version fixed by Max1mums
*/


version := 4.1	; Used for the GUI Title. Keeping the version number in the scripts filename prevents reusing previous versions settings
debug := false	; if true changes the working dir and enables Hotkeys for reload and ListVars at the bottom of the script
#NoEnv
#SingleInstance, Force
SendMode Input
SetWorkingDir %A_ScriptDir%

if debug
	sfsoSettingsFolder = %A_WorkingDir%	; old behaviour for easier testing
else
	sfsoSettingsFolder = %A_AppData%\SFSO	; causes configuration data to be safed in the current users AppData folder

SetBatchLines, -1
SetTitleMatchMode, 2

if A_IsUnicode
{
	MsgBox, SFSO requires the ANSI (32-bit) installation of AutoHotkey_L.`nPlease rerun the AutoHotkey setup. SFSO will now exit.
	ExitApp
}

goSub, loadSettings
goSub, requestAdminRights
goSub, setPSLogFilePath
SetTimer, checkPSVersion, 1000

OnMessage(0x232,"WM_EXITSIZEMOVE")

;==============================================================
RegSofar=0
OpenTables=0
trows=17
SysGet,mon, MonitorworkArea
fivesec=0
ft:=0
two=0
ddlist4=Off|
ddlist5=Off|
ddlist6=Off|
ddlist7=Off|
LobbyList=Default|Black||
ddlist2:=ddlist2 . 1 . "|"
ddlist2:=ddlist2 . 2 . "|"
Loop 100
{
	two:=two+2
	ddlist3:=ddlist3 . two . "|"
	ddlist:=ddlist . A_index . "|"
	If (A_index<51)
	{
		fivesec:=fivesec+5
		ddlist2:=ddlist2 . fivesec . "|"
		ddlist6:=ddlist6 . fivesec . "|"
		If (A_index<22)
		{
			ddlist7:=ddlist7 . A_Index . "|"
			If (A_index<16)
			{
				ddlist4:=ddlist4 . A_index . "|"
			}
		}
	}
	else
	{
		ft:=ft+15
		ddlist5:=ddlist5 . ft . "|"
	}
}
ddlist3:=ddlist3 . 9999 . "|"
Gosub, BuildGui
Return
;==============================================================
;==============================================================

; TODO: incorporate reads from getIni 
loadSettings:
IniRead, GuiScreenPosX		, %sfsoSettingsFolder%\SFSO.ini, Settings, GuiScreenPosX	, 10
IniRead, GuiScreenPosY		, %sfsoSettingsFolder%\SFSO.ini, Settings, GuiScreenPosY	, 10
IniRead, requestElevation	, %sfsoSettingsFolder%\SFSO.ini, Settings, requestElevation	, ask
IniRead, psSettingsFolder	, %sfsoSettingsFolder%\SFSO.ini, Settings, psSettingsFolder	, foo
IniRead, psLastKnownVersion	, %sfsoSettingsFolder%\SFSO.ini, Settings, psLastKnownVersion	, 7.1.2.5
IniRead, psRegisterButton	, %sfsoSettingsFolder%\SFSO.ini, Settings, psRegisterButton	, PokerStarsButtonClass10
IniRead, psGamesList		, %sfsoSettingsFolder%\SFSO.ini, Settings, psGamesList		, PokerStarsListClass4
return

; Attempts to find the correct path for pokerstars.log.0 utilizing the
; 'Open My Settings Folder' entry in PokerStars clients 'Help' menu.
; If that fails it will present a dialog for manual selection
setPSLogFilePath:
IfNotExist, %psSettingsFolder%
{
	ifWinNotExist, PokerStars Lobby ahk_class #32770
		MsgBox, Please ensure PokerStars is running before proceeding.
	WinWait, PokerStars Lobby ahk_class #32770
	; auto detection will fail if there is already a Explorer window whose address points to a folder named 'pokerstars'
	; as a workaround we first give focus to PS lobby
	; then we select "Help > Open My Settings Folder" in Lobby menu
	; this opens and activates the Explorer window we are looking for
	WinActivate, PokerStars Lobby ahk_class #32770
	WinMenuSelectItem, PokerStars Lobby ahk_class #32770,, Help, Open My Settings Folder
	WinWaitActive, PokerStars ahk_class CabinetWClass,, 2	; wait up to 2 seconds for the Explorer window to open
	if not ErrorLevel
	{
		WinGetText, visibleText
		WinClose
		StringTrimLeft, visibleText, visibleText, 9		; removes 'Address: ' at the beginning
		StringGetPos, pathEndPos, visibleText, `r
		StringLeft, psSettingsFolder, visibleText, pathEndPos	; removes everything from the first CR onwards
	}
	else
	{
		MsgBox, Auto detection of PokerStars settings folder failed.`nClick 'OK' to manually select the folder
		if A_OSVersion in WIN_2003,WIN_XP,WIN_2000
			startFolder := %A_AppData%
		else EnvGet, startFolder, LOCALAPPDATA	; for Win Vista/7/8
		FileSelectFolder, psSettingsFolder, %startFolder%, 0, Select Pokerstars settings folder
	}
	IniWrite, %psSettingsFolder%, %sfsoSettingsFolder%\SFSO.ini, Settings, psSettingsFolder
}
logfile := psSettingsFolder . "\pokerstars.log.0"
IfNotExist %logfile%
{
	MsgBox, Could not find "%logfile%", please recheck the configuration.
	ExitApp
}
return

; TODO: check integrity level of PS client first and only elevate script if necessary
;	See http://msdn.microsoft.com/en-us/library/bb625966.aspx
requestAdminRights:
if (requestElevation == "ask" and not A_IsAdmin)	;no point in asking if SFSO is already run as admin
{
	MsgBox, 4100,, Do you run PokerStars as Administrator?	; SFSO only needs Admin rights if PS is running elevated hence we be nice and ask first
	ifMsgBox, Yes
		requestElevation := true
	else
		requestElevation := false
	IniWrite, %requestElevation%, %sfsoSettingsFolder%\SFSO.ini, Settings, requestElevation	; ensure requestElevation is available to the second instance
}
if (requestElevation and not A_IsAdmin)
{
	Run *RunAs "%A_ScriptFullPath%",, UseErrorLevel	; start a second, elevated instance of SFSO
	ExitApp
}
return

; gets called by a Timer until PS client is running
; checks if the client got updated and if so displays a reminder for the ID Tool
checkPSVersion:
ifWinExist PokerStars Lobby ahk_class #32770
{
	SetTimer, checkPSVersion, Off
	WinGet, psExePath, ProcessPath
	FileGetVersion, psCurrentVersion, %psExePath%
	if (psCurrentVersion != psLastKnownVersion)
		MsgBox,, PokerStars update detected, If SFSO is not registering for games use the "Identify PS controls" tool from the advanced tab
			. You might also have to use the tool if you change your Lobby theme.
}
return

IdentifyPSControls:
Gui, +Disabled	; disable the main window
Gui, idTool:+Owner -MinimizeBox +ToolWindow
Gui, idTool:Add, Text,, Identify the following controls in the`nPokerStars client by right clicking on them:

Gui, idTool:Add, Text, Section	, Tourney List:
Gui, idTool:Add, Text,		, Register Button:

Gui, idTool:Add, Edit, w130 ys	ReadOnly vPSGamesList		; no defaults for the edit boxes to provide visual clues for successful selection
Gui, idTool:Add, Edit, w130	ReadOnly vPSRegisterButton

Gui, idTool:Add, Button, Section vIdToolOK disabled	, OK		; vIdToolOK only provides a reference to allow enabling the button later on
Gui, idTool:Add, Button, ys				, Cancel

WinActivate, PokerStars Lobby ahk_class #32770

x := GuiScreenPosX + 30
y := GuiScreenPosY + 30
Gui, idTool:Show, x%X% y%Y%, SFSO ID Tool

HotKey, $RButton, getPSControl, On
return

; if the user right clicks on a fitting PS control we update the ID Tool window
; right clicks anywhere else get send through unaltered
getPSControl:
MouseGetPos, , , id, selectedControl
WinGetClass, class, ahk_id %id%
WinGetTitle, title, ahk_id %id%
if (InStr(class, "#32770") and InStr(title, "PokerStars Lobby"))
{
	IfInString, selectedControl, PokerStarsButtonClass
		{
		GuiControl, idTool:, psRegisterButton, %selectedControl%
		buttonSelected := true
		}
	IfInString, selectedControl, PokerStarsListClass
		{
		GuiControl, idTool:, psGamesList, %selectedControl%
		listSelected := true
		}
	if (buttonSelected and listSelected)
		GuiControl, idTool:Enable, IdToolOK
} else Click right
return

; uses a fallthrough since the only difference between all buttons is the 'Submit' after clicking 'OK'
idToolButtonOK:
Gui, idTool:Submit
idToolButtonCancel:
idToolGuiClose:
HotKey, $RButton, Off
Gui, idTool:Destroy
Gui, 1:-Disabled
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

; TODO: remove hardcoded control placement
BuildGui:
Gui, color, white
Gui, font, cOlive
Gui, add, tab, h340 w240, General|Advanced Settings
Gui, add, text, , Auto-register
Gui, add, Checkbox, yp xp+80 Check3 Checked-1 vRegister
Gui, add, text, yp xp+30, Reg. next if full?
Gui, add, Checkbox, yp xp+80 VAutoifFull


Gui, add, text,xp-190 yp+30 , Register every (sec):
Gui, add, DropDownList, w50 yp-5 xp+140  vInterval1, %ddlist2%
Gui, add, text, xp-140 yp+30, No of SNG:s to keep open:
Gui, add, DropDownList, w50 yp-5 xp+140 vKeepOpen , %ddlist%
Gui, add, text,xp-140 yp+30, Limit total SNG:s to:
Gui, add, DropDownList, w50 yp-5 xp+140 vTotalLimit , %ddlist3%
Gui, add, text,xp-140 yp+30, Limit total time to (min):
Gui, add, DropDownList, w50 yp-5 xp+140 vLimitTime , %ddlist5%

Gui, add, text, xp-140 yp+30 cred vcdown w200
Gui, add, text, xp  yp+30 w200 vRegSofar, SNG:s registered so far:
Gui, add, text,  w200 vOpenTables, Tables open/waiting:
Gui, add, text, w200 cRed vStatus, Status: Idle
Gui, add, Button, w68 ggetgui, &Submit+Run
Gui, add, text, xp+72 yp+5, (Autosaves your settings)
Gui, Add, Button, Disabled xp-72 yp+20 w48 h20 Center , &Resume
Gui, Add, Button, Disabled  w45 h20 yp xp+48 Center , &Pause
Gui, Add, Button, w80 h20 yp xp+45 Center globbyrestore, &Lobby restore
; Gui, Add, Button, w45 h20 yp xp+80 gDonate, &Donate	; deactivated for now as Everlong effectively stopped working on this ages ago
Gui, tab, 2

Gui, add, text,x25 y65 , Close lobbies every (sec):
Gui, add, DropDownList, w50 yp-5 xp+140  vCloseInterv, %ddlist6%
Gui, add, text, xp-140 yp+18 , (manually Close with ctrl+e)
Gui, add, text, yp+30, Disable if no user Input (min):
Gui, add, DropDownList, w50 yp-5 xp+140 vGuardtimer Choose1 , %ddlist4%
Gui, add, text, xp-140 yp+30 ,Batch-register?
Gui, add, Checkbox,yp xp+140 vBatchReg
Gui, add, text, yp+20 xp-140 ,SetReg* mode?
Gui, add, Checkbox,yp xp+140 vSetReg
Gui, add, text, yp+20 xp-140 ,Minimize lobby?
Gui, add, Checkbox,yp xp+140 vMinlob
Gui, add, Text, xp-140 yp+30, Times to scroll down:
Gui, add, DropDownList, w50 yp-5 xp+140 vscrldwn, %ddlist7%
Gui, add, Text, xp-140 yp+25, Always start at top of lobby?
Gui, add, Checkbox, yp xp+140 vTopReturn
Gui, add, Text, xp-140 yp+25, Request Admin Privileges?`n(requires restart)
Gui, add, Checkbox, yp xp+140 Checked%requestElevation% vrequestElevation
Gui, add, Button, xp-140 yp+25 gIdentifyPSControls , Identify PS controls

Gosub, GetIni
Gui, show, x%GuiScreenPosX% y%GuiScreenPosY%, SFSO %version%
Gui, +HwndmainGuiId
Return

getgui:
GuiControl,, Register, -1
Register = 1
Gui, Submit, NoHide
displayedTime=

Gosub, saveSettings
PausedTime:=LimitTime
Gosub, TimeLimit
interval:=interval1*1000

If interval is not Number
interval=off

If guardtimer is not Number
{
SetTimer, safeguard, off
}
Else
{
killtime:=guardtimer*60000
SetTimer, safeguard, 1000
}
if CloseInterv is not number
SetTimer, NukeLobbies, off
else
{
lobclose:=CloseInterv*1000
SetTimer, NukeLobbies, %lobclose%
}
register=1
sleep,-1
Gosub, ButtonResume
Return

Safeguard:
If (A_TimeIdle > killtime)
{
Gosub, ButtonPause
GuiControl, , cdown, Stopped  due to inactivity!!! %displayedTime%
}
Return

TimeLimit:
If LimitTime is Number
{
allowedMinutes := LimitTime
endTime := A_Now
endTime += %allowedMinutes%, Minutes
SetTimer, CountDown, 1000
}
Else
{
SetTimer, CountDown, off
sleep,-1
GuiControl, , cdown, Time Limit off
}
Return

Countdown:
remainingTime := endTime
EnvSub remainingTime, %A_Now%, Seconds
m := remainingTime // 60
s := Mod(remainingTime, 60)
displayedTime := Format3Digits(m) ":" Format2Digits(s)
GuiControl, , cdown, Running another (mm:ss): %displayedTime%
If (A_now > endTime)
{
SetTimer, Countdown, off
Gosub, ButtonPause
GuiControl, , cdown, Time Limit reached.
}
Return

GuiClose:
Gui, Submit
Gosub, saveSettings
ExitApp

ButtonResume:
Gui, Submit, NoHide
GuiControl, Disable, &Resume
GuiControl, Enable, &Pause
if LimitTime is Number
If PausedTime is Number
LimitTime:=PausedTime
Gosub, TimeLimit
GuiControl, , Register, -1
Register:=1
settimer, AutoReg,37
OpenTables:=0
tables=
OpenTables:=CountTourneys(1)
Gosub,Register
SetTimer, Register, %Interval%
sleep,-1
Return

ButtonPause:
Critical
Gui, Submit, NoHide
if LimitTime is Number
PausedTime:=remainingTime/60
Register:=0
settimer, AutoReg,off
SetTimer, Countdown, off
SetTimer, Register, off
GuiControl, Disable, Pause
GuiControl, Enable, Resume
GuiControl, , Register, 0
GuiControl, , cdown, Manually Paused %displayedTime%
GuiControl, , Status, Status: Waiting ;TEST
Return

Register:
SetTitleMatchMode, 2
WinGet, LobbyID, id, PokerStars Lobby - ahk_class #32770	; TODO: notify user to log into PS, atm SFSO shows 'Lobby not found'

If !LobbyID
{
Gosub, ButtonPause
GuiControl,, Status, Status: PokerStars Lobby not found
Gui, show, NoActivate
Return
}
If (TopReturn=1)
{
ControlSend, %psGamesList%, {NumpadUp 20}, ahk_id%lobbyid%
}
WinGet, PhysicalTables, list,Table ahk_class PokerStarsTableFrameClass
If PhysicalTables is not Number
PhysicalTables:=0
If (PhysicalTables >= KeepOpen)
{
GuiControl,, Status, Set Full waiting
Return
}
OpenTables:=CountTourneys()
If OpenTables is not Number
OpenTables:=0
GuiControl, , OpenTables, Tables open/waiting: %OpenTables%
GuiControl, , RegSofar, SNG:s registered so far: %RegSofar%

If (RegSofar >= TotalLimit)
{
Gosub, ButtonPause
GuiControl, , cdown, SNG Total Limit reached
GuiControl, , Status, Status: Idle ;TEST
Return
}
If (OpenTables >= TotalLimit)
{
Gosub, ButtonPause
GuiControl, , cdown, SNG Total Limit reached
GuiControl, , Status, Status: Idle ;TEST
Return
}
If (OpenTables>=KeepOpen)
{
GuiControl, , OpenTables, Tables open/waiting: %OpenTables% (Set full)
GuiControl, , Status, Status: Waiting ;TEST
Return
}
Else
{
If (BatchReg=1)
{
Times:= KeepOpen - OpenTables
RegSNGexec(LobbyID, Times, scrldwn)
}
Else
{
RegSNGexec(LobbyID, 1, scrldwn)
}
}
Return

saveSettings:
IniWrite, %AutoIfFull%	, %sfsoSettingsFolder%\SFSO.ini, Settings, AutoIfFull
IniWrite, %TopReturn%	, %sfsoSettingsFolder%\SFSO.ini, Settings, TopReturn
IniWrite, %scrldwn%	, %sfsoSettingsFolder%\SFSO.ini, Settings, scrldwn
IniWrite, %BatchReg%	, %sfsoSettingsFolder%\SFSO.ini, Settings, BatchReg
IniWrite, %Setreg%	, %sfsoSettingsFolder%\SFSO.ini, Settings, SetReg
IniWrite, %Minlob%	, %sfsoSettingsFolder%\SFSO.ini, Settings, MinLob
IniWrite, %Interval1%	, %sfsoSettingsFolder%\SFSO.ini, Settings, Interval1
IniWrite, %CloseInterv%	, %sfsoSettingsFolder%\SFSO.ini, Settings, CloseInterv
IniWrite, %KeepOpen%	, %sfsoSettingsFolder%\SFSO.ini, Settings, KeepOpen
IniWrite, %TotalLimit%	, %sfsoSettingsFolder%\SFSO.ini, Settings, TotalLimit
IniWrite, %GuardTimer%	, %sfsoSettingsFolder%\SFSO.ini, Settings, GuardTimer
IniWrite, %LimitTime%	, %sfsoSettingsFolder%\SFSO.ini, Settings, LimitTime

IniWrite, %GuiScreenPosX%	, %sfsoSettingsFolder%\SFSO.ini, Settings, GuiScreenPosX
IniWrite, %GuiScreenPosY%	, %sfsoSettingsFolder%\SFSO.ini, Settings, GuiScreenPosY
IniWrite, %requestElevation%	, %sfsoSettingsFolder%\SFSO.ini, Settings, requestElevation
IniWrite, %psCurrentVersion%	, %sfsoSettingsFolder%\SFSO.ini, Settings, psLastKnownVersion
IniWrite, %psRegisterButton%	, %sfsoSettingsFolder%\SFSO.ini, Settings, psRegisterButton
IniWrite, %psGamesList%		, %sfsoSettingsFolder%\SFSO.ini, Settings, psGamesList
Return

; TODO: provide defaults for all iniReads, move them to loadSettings and merge the lines below with getGui:
GetIni:
IfExist, %sfsoSettingsFolder%\SFSO.ini
{
IniRead, AutoIfFull	, %sfsoSettingsFolder%\SFSO.ini, Settings, AutoIfFull
IniRead, TopReturn	, %sfsoSettingsFolder%\SFSO.ini, Settings, TopReturn	, 0
IniRead, scrldwn	, %sfsoSettingsFolder%\SFSO.ini, Settings, scrldwn
IniRead, BatchReg	, %sfsoSettingsFolder%\SFSO.ini, Settings, BatchReg
IniRead, SetReg		, %sfsoSettingsFolder%\SFSO.ini, Settings, SetReg	, 1
IniRead, MinLob		, %sfsoSettingsFolder%\SFSO.ini, Settings, MinLob	, 0
IniRead, Interval1	, %sfsoSettingsFolder%\SFSO.ini, Settings, Interval1
IniRead, CloseInterv	, %sfsoSettingsFolder%\SFSO.ini, Settings, CloseInterv
IniRead, KeepOpen	, %sfsoSettingsFolder%\SFSO.ini, Settings, KeepOpen
IniRead, TotalLimit	, %sfsoSettingsFolder%\SFSO.ini, Settings, TotalLimit
IniRead, GuardTimer	, %sfsoSettingsFolder%\SFSO.ini, Settings, GuardTimer	, Off
IniRead, LimitTime	, %sfsoSettingsFolder%\SFSO.ini, Settings, LimitTime	, Off

GuiControl, , AutoIfFull, %AutoIfFull%
StringReplace, ddlist7, ddlist7, %scrldwn%, %scrldwn%|
GuiControl, , scrldwn, |%ddlist7%
GuiControl, , BatchReg, %BatchReg%
GuiControl, , SetReg, %SetReg%
GuiControl, , MinLob, %MinLob%
GuiControl, , TopReturn, %TopReturn%
StringReplace, ddlist2, ddlist2, %interval1%, %Interval1%|
GuiControl, , Interval1, |%ddlist2%
StringReplace, ddlist6, ddlist6, %CloseInterv%, %CloseInterv%|
GuiControl, , CloseInterv, |%ddlist6%
StringReplace, ddlist, ddlist, %KeepOpen%, %KeepOpen%|
GuiControl, , KeepOpen, |%ddlist%
StringReplace, ddlist3, ddlist3, %TotalLimit%, %TotalLimit%|,
GuiControl, , TotalLimit, |%ddlist3%
StringReplace, ddlist4, ddlist4, %GuardTimer%, %GuardTimer%|
GuiControl, , GuardTimer, |%ddlist4%
StringReplace, ddlist5, ddlist5, %LimitTime%, %LimitTime%|
GuiControl, , LimitTime, |%ddlist5%
}
Return

#e::
gosub,NukeLobbies
Return

NukeLobbies:
SetTitleMatchMode, 2
GroupAdd, TLobbies, Lobby ahk_class PokerStarsTableFrameClass,,, PokerStars Lobby
GroupClose, TLobbies, A
Return

#H::
WinHide, ahk_id %mainGuiId%
return

#S::
WinShow, ahk_id %mainGuiId%
return

/* Is this an artefact from an earlier version or does CountTourneys() have a side effect used with this Hotkey?
#F11::
TmpSetReg:=SetReg
SetReg=0
CountTourneys()
SetReg:=TmpSetReg
Return
*/

FindLobby:
If (%A_GuiEvent% = DoubleClick)
{
LV_GetText(TournId,A_EventInfo)
TournID:=SubStr(TournID, 1,10)
WinMenuSelectItem, PokerStars Lobby,, Requests, Find a Tournament
WinWait, Find Tournament ahk_class #32770, , 10
WinGet, fat, id
ControlFocus, Edit1, ahk_id%fat%
Sleep, -1
ControlSend, Edit1, %TournId%, ahk_id%fat%
ControlFocus, Button1, ahk_id%fat%
Sleep, -1
ControlSend, Button1, {Space}, ahk_id%fat%
}
Return

Donate:
donation()
Return

Format2Digits(_val) {
_val :=Round(_val) + 100
StringRight _val, _val, 2
Return _val
}

Format3Digits(_val) {
_val :=Round(_val) + 1000
StringRight _val, _val, 3
StringTrimRight, FirstZ, _val, 2
If FirstZ=0
{
StringTrimLeft, _val, _val, 1
}
StringTrimRight, FirstZ, _val, 1
If FirstZ=0
{
StringTrimLeft, _val, _val, 1
}
Return _val
}

LobbyRestore:
WinGet, lobbyid, id, PokerStars Lobby
WinShow, ahk_id%lobbyid%
;WinMove, ahk_id%lobbyid%,,0,0	; why is this in here?
return


RegSNGexec(id, times, scrldwn) {
global RegSofar
global Register
global OpenTables
global KeepOpen
global TotalLimit
global psRegisterButton
global AutoIfFull
global psGamesList
Loop %times%
{
ControlSend, %psGamesList%, {NumpadUp 20}, ahk_id%id%
If (OpenTables >= KeepOpen)
Exit
If (OpenTables >= TotalLimit)
Exit
ClickdirectionCount=0
direction=0
GuiControl, , Status, Status: Registering ;TEST
Loop 16
{
If (Register=0)
{
GuiControl, , Status, Status: Idle ;TEST
Exit
}
ControlGet, v, Visible, , %psRegisterButton%, ahk_id%id%
If (v = 0)
If (scrldwn!="Off")
{
If (ClickdirectionCount<scrldwn) {
If (direction=0) {
ControlSend, %psGamesList%, {NumpadDown}, ahk_id%id%
} Else {
ControlSend, %psGamesList%, {NumpadUp}, ahk_id%id%
}
ClickdirectionCount:=ClickdirectionCount+1
} Else {
If (direction=0) {
direction:=1
} Else {
direction:=0
}
ClickdirectionCount:=0
}
Sleep,1000
}


If ( v = 1 ) {
wingetclass,class,A
SetTitleMatchMode, 2
ControlSend, %psRegisterButton%, {Space}, ahk_id%id%
ControlSend, %psRegisterButton%, {Space}, ahk_id%id%
WinWait, Tournament Registration ahk_class #32770,,1
{
WinGet, regid, id, Tournament Registration ahk_class #32770
controlget,vis,visible,,Button2,ahk_id%regid%
if vis
{
 If (AutoIfFull = 1)
 {
 Control,Check,,Button2, ahk_id%regid%
 ;ControlSend, Button2, {Space}, ahk_id%regid%
 Sleep, 30
 }
ControlSend, PokerStarsButtonClass1, {Space}, ahk_id%regid%
}
}
sleep,30
WinWait, Tournament Registration ahk_class #32770,,1
{
WinGet, regid, id, Tournament Registration ahk_class #32770
controlget,vis,visible,,Button2,ahk_id%regid%
if !vis
winclose,ahk_id%regid%
;ControlSend, PokerStarsButtonClass1, {Space}, ahk_id%regid%
}
GuiControl, , Status, Status: Waiting ;TEST
;if class=PokerStarsTableFrameClass
;winactivate,ahk_class PokerStarsTableFrameClass
Break
}
}
}
}
return

AutoReg:
AutoReg()
return

AutoReg()
{
global AutoIfFull
settitlematchmode,2
IfWinExist, Tournament Registration ahk_class #32770
{
winget,id,id,
controlget,vis,visible,,Button2,ahk_id%id%
if vis
{
If (AutoIfFull = 1)
{
ControlFocus, Button2, ahk_id%id%
Sleep, -1
ControlSend, Button2, {Space}, ahk_id%id%
Sleep, 30
}
ControlSend, PokerStarsButtonClass1, {Space}, ahk_id%id%
}
else
winclose,ahk_id%id%
;ControlSend, PokerStarsButtonClass1, {Space}, ahk_id%id%
}
}
return

CountTourneys(mode=0) {
global logfile
global RegSofar,regtourneys,tables
If (SetReg=1)
{
Return 0
}
if mode=0
log := CheckFile(logfile)
else
log := CheckFile(logfile,1)
;fileread,log, %logfile%
Loop, Parse, log, `n,
{
tnumber=
If ((instr(A_loopField,"TournFrame")>0) && !(instr(A_loopField,"::")>0) && !(instr(A_loopField,"~")>0)) || (instr(A_loopField,"RT add")>0)
{
 if instr(A_loopField,"TournFrame")>0
 {
 tnumber:=RegExReplace(A_loopField, "TournFrame '", "")
 stringleft,tnumber,tnumber,instr(tnumber,A_space)-2
 }
 else
 if instr(A_loopField,"RT add")>0 
 {
 tnumber:=RegExReplace(A_loopField, "RT add ", "")
 if instr(tnumber,A_space)
 StringLeft, tnumber, tnumber, instr(tnumber,A_space)-1
 }
 tnumber:=RegExReplace(tnumber, "[`n,`r]", "")
 if !instr(tables,tnumber)
 listadd(tables,tnumber)
}
else
If (instr(A_loopField,"RT remove")>0) || (instr(A_loopField,"~TournFrame")>0)
{
 if instr(A_loopField,"~TournFrame")>0
 {
 tnumber:=RegExReplace(A_loopField, "~TournFrame '", "")
 stringleft,tnumber,tnumber,instr(tnumber,A_space)-2
 }
 else
 if instr(A_loopField,"RT remove")>0
 stringtrimleft,tnumber,A_loopField,instr(A_loopField,A_space,"",0)
 tnumber:=RegExReplace(tnumber, "[`n,`r]", "")
 if instr(tables,tnumber)
 listDelItem(tables,tnumber)
}
}
log=
tcount:=0
Loop, Parse, tables, -,
{
if A_Loopfield is number
{
tcount++
if !(instr(regtourneys,A_Loopfield)>0)
{
listadd(regtourneys,A_Loopfield)
if mode=0
RegSofar++
}
}
}
return tcount
}

; TODO: get rid of this coding horror (as well as checkFile)
;	at the very least this needs to be updated to work on Unicode builds, but
ReplaceByte( hayStackAddr, hayStackSize, ByteFrom=0, ByteTo=1, StartOffset=0, NumReps=-1)
{	Static fun
	IfEqual,fun,
	{
		h=
		( LTrim join
			5589E553515256579C8B4D0C8B451831D229C17E25837D1C00741F8B7D0801C70FB6451
			00FB65D14FCF2AE750D885FFF42FF4D1C740409C975EF9D89D05F5E5A595BC9C21800
		)
		VarSetCapacity(fun,StrLen(h)//2)
		Loop % StrLen(h)//2
			NumPut("0x" . SubStr(h,2*A_Index-1,2), fun, A_Index-1, "Char")
	}
	Return DllCall(&fun
		, "uint",haystackAddr, "uint",hayStackSize, "short",ByteFrom, "short",ByteTo
		, "uint",StartOffset, "int",NumReps)
}

CheckFile(File, mode=0) {
   ; THX Sean for File.ahk : http://www.autohotkey.com/forum/post-124759.html
   Static CF := ""   ; Current File
   Static FP := 0    ; File Pointer
   Static OPEN_EXISTING := 3
   Static GENERIC_READ := 0x80000000
   Static FILE_SHARE_READ := 1
   Static FILE_SHARE_WRITE := 2
   Static FILE_SHARE_DELETE := 4
   Static FILE_BEGIN := 0
   BatchLines := A_BatchLines
   SetBatchLines, -1
   If (File != CF) {
      CF := File
      FP := 0
   }
   hFile := DllCall("CreateFile"
                  , "Str",  File
                  , "Uint", GENERIC_READ
                  , "Uint", FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_SHARE_DELETE
                  , "Uint", 0
                  , "Uint", OPEN_EXISTING
                  , "Uint", 0
                  , "Uint", 0)
   If (!hFile) {
      CF := ""
      FP := 0
      SetBatchLines, %BatchLines%
      Return False
   }
   DllCall("GetFileSizeEx"
         , "Uint",   hFile
         , "Int64P", nSize)
   if mode=1
   FP:=1
   If (FP = 0 Or nSize <= FP) {
      FP := nSize
      SetBatchLines, %BatchLines%
      DllCall("CloseHandle", "Uint", hFile) ; close file
     Return False
   }
   DllCall("SetFilePointerEx"
         , "Uint",  hFile
         , "Int64", FP
         , "Uint",  0
         , "Uint",  FILE_BEGIN)
   VarSetCapacity(Tail, Length := nSize - FP, 0)
   DllCall("ReadFile"
         , "Uint",  hFile
         , "Str",   Tail
         , "Uint",  Length
         , "UintP", Length
         , "Uint",  0)
   DllCall("CloseHandle", "Uint", hFile)
   ReplaceByte( &Tail, Length)
   VarSetCapacity(Tail, -1)
   FP := nSize
   SetBatchLines, %BatchLines%
   Return Tail
}


listAdd( byRef list, item, del="-" ) {
  list:=( list!="" ? ( list . del . item ) : item )
  return list
}

listDelItem( byRef list, item, del="-") {
  ifEqual, item,, return list
  list:=del . list . del
  StringReplace, list, list, %item%%del%
  StringTrimLeft, list, list, 1
  StringTrimRight, list, list, 1
  return list
}

donation() {
WinMenuSelectItem, PokerStars Lobby,, Requests, Transfer Funds...
WinWait, Transfer Funds ahk_class #32770, , 10
WinGet, tf, id
ControlFocus, Edit2, ahk_id%tf%
ControlSetText, Edit2, Attilio
ControlFocus, Edit1, ahk_id%tf%
Sleep, -1
ControlSetText, Edit1,
GuiControl, Disable, Donate
}

lobbyStars() {
SetTitleMatchMode 2
WinGet, id, id, PokerStars Lobby - ahk_class #32770
Return id
}

~^!Q::
ExitApp


#if debug
Esc::Reload

Pause::
ListVars
pause
return
#if