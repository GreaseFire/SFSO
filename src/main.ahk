/*
Author:    Everlong@2p2 Code assembled from misc sources, thanks to _dave_, chris228, finnisher
Author:    Max1mums
Author:    GreaseFire

 v4.2
 - Restructured the GUI
 - Restored full functionality for all options
 - General cleanup
 - Added check to ensure correct AHK version is used
 - Added option to switch focus back to games after registering
 
 v4.11
 - Bugfix: 4.1 didn't actually save its Settings (d'oh!)
 
 v4.1
 - SFSO will now remember its on screen position
 - Added check whether script is running in ANSI mode
 - Added auto detection for pokerstars logfile
 - Request Admin privileges if called for
 - Added tool to identify controls in PS client
 - Settings are now kept in the current users AppData folder

 v4.01
 added: option to autubuyin if full, hide/show window
 fixed issue with skipping first sng in lobby 

 4.0 version fixed by Max1mums
*/


sfsoVersion = 4.2	; Used for the GUI Title and to migrate settings
debug := false		; if true SFSO saves its settings in the working dir and enables Hotkeys for reload and ListVars at the bottom of the script
#NoEnv
#SingleInstance, Force
SendMode Input
SetWorkingDir %A_ScriptDir%
;#Warn
;#Warn, LocalSameAsGlobal, Off
SetBatchLines, -1
SetTitleMatchMode, 2

Menu, tray, tip, SFSO %sfsoVersion%

if debug
	sfsoSettingsFolder = %A_WorkingDir%		; old behaviour for easier testing
else
	sfsoSettingsFolder = %A_AppData%\SFSO	; causes configuration data to be safed in the current users AppData folder

IfNotExist, %sfsoSettingsFolder%\			; ensure AppData\SFSO\ exists, otherwise saving Settings won't work
	FileCreateDir, %sfsoSettingsFolder%

goSub, initGlobalVars
goSub, loadSettings
if firstRun
{
	welcomeText := "Before you start using the program make sure you`n`n"
	welcomeText .= "`tFILTER YOUR POKERSTARS LOBBY FOR`n`tONLY THOSE GAMES YOU INTEND TO PLAY`n`n"
	welcomeText .= "Please refer to the readme for further details and explanation of the settings available."
	MsgBox, 4096, Welcome to Stars Filtered SNG Opener (SFSO), %welcomeText%
	IniWrite, 0, %sfsoSettingsFolder%\SFSO.ini, Settings, firstRun
	welcomeText =
}
goSub, requestAdminRights
goSub, setPSLogFilePath
SetTimer, checkPSVersion, 1000
OnMessage(0x232,"WM_EXITSIZEMOVE")	; called after the GUI got moved
Gosub, BuildGui
Return
;==============================================================
#Include GUI_main.ahk
#Include GUI_IDTool.ahk
#Include settings.ahk
#Include utility.ahk
#Include PSLogfileBroker.ahk
#Include hotkeys.ahk
;==============================================================


run:
Gui, Submit, NoHide
if (TotalLimitEnabled == false and LimitTimeEnabled == false)
{
	MsgBox, 8244, No limits set, Without a limit for total amount and/or total time SFSO will register indefintely
	  . Are you sure you want to continue?
	ifMsgBox, No
		return
}
displayedTime =
PausedTime := LimitTime
Gosub, TimeLimit
interval := RegisterInterval*1000
If guardtimerEnabled
{
	killtime := guardtimer*60000
	SetTimer, safeguard, 1000
}
Else
	SetTimer, safeguard, off
if CloseIntervEnabled
{
	lobclose := CloseInterv*1000
	SetTimer, NukeLobbies, %lobclose%
}
else
	SetTimer, NukeLobbies, off
sleep,-1
Gosub, ButtonResume
Return


Safeguard:
If (A_TimeIdle > killtime)
{
	Gosub, ButtonPause
	setStatus(USER_INACTIVE)
}
Return


TimeLimit:
If LimitTimeEnabled
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
	setStatus(TIME_LIMIT_OFF)
}
Return


Countdown:
remainingTime := endTime
EnvSub remainingTime, %A_Now%, Seconds
m := remainingTime // 60
s := Mod(remainingTime, 60)
displayedTime := Format3Digits(m) ":" Format2Digits(s)
setStatus(REMAINING_TIME)
If (A_now > endTime)
{
	SetTimer, Countdown, off
	Gosub, ButtonPause
	setStatus(TIME_LIMIT_REACHED)
}
Return


ButtonResume:
Gui, Submit, NoHide
GuiControl, Disable, Resume
GuiControl, Enable, Pause
if LimitTimeEnabled
	if PausedTime is Number
		LimitTime := PausedTime
Gosub, TimeLimit
stopRegistering := false
OpenTables := 0
tables=
waitForSetFinish := false
OpenTables := CountTourneys(1)
selectNextGame(true)	; make sure we start at the top of the list
if minLob
	gosub, moveLobby
Gosub,Register
SetTimer, Register, %Interval%
sleep,-1
Return


ButtonPause:
Critical
Gui, Submit, NoHide
if LimitTimeEnabled
	PausedTime := remainingTime/60
stopRegistering := true
SetTimer, Countdown, off
SetTimer, Register, off
GuiControl, Disable, Pause
GuiControl, Enable, Resume
if minLob
	gosub, buttonShowLobby
setStatus(MANUAL_PAUSE)
Return


; called from a timer whose frequency is determined by RegisterInterval
; checks how many games are open/waiting
; determines if any more games need to be registered
; if yes it will register for either:
;	one game and then return
;	as many games as currently needed (if batch register is enabled)
; TODO: SetRegMode (register in sets) should be implemented in here
; TODO: account for scrlDown value - only batch register an amount that is generally available
Register:
;WinGet, LobbyID, id, PokerStars Lobby - ahk_class #32770	; TODO: notify user to log into PS, atm SFSO shows 'Lobby not found'
IfWinNotExist, PokerStars Lobby - ahk_class #32770
{
	Gosub, ButtonPause
	setStatus(LOBBY_NOT_FOUND)
	Return
}
; using winGet might speed things up by avoiding countTourneys() call
; but if countTourneys() only reads newly added lines from logfile this might not be necessary
; in fact calling countTourneys() more often might be better than that
; TODO: remove the winGet stuff if countTourneys() is that smart
/* WinGet, PhysicalTables, list,Table ahk_class PokerStarsTableFrameClass
If (PhysicalTables >= KeepOpen)
{
	setStatus(SET_FULL)
	Return
}
 */
OpenTables := CountTourneys()
If OpenTables is not Number
	OpenTables := 0
;setStatus(TABLES)	; implicitly done on any call to setStatus() now
If (RegSofar >= TotalLimit or OpenTables >= TotalLimit) ; assert openTables <= regSoFar -> second part should not matter
{
	Gosub, ButtonPause
	setStatus(TOTAL_LIMIT_REACHED)
	Return
}
if (openTables == 0)
	waitForSetFinish := false
If (OpenTables >= KeepOpen) or waitForSetFinish
{
	if setReg
		waitForSetFinish := true
	setStatus(SET_FULL)
	return
}

setStatus(REGISTERING)
times := 1
If (BatchReg and (openTables == 0))
{
	times := KeepOpen - OpenTables
	times := times > scrlDwn ? scrlDwn : times
	; assert times <= scrlDwn
}
registerForGame(times)	

Return

moveLobby:
SysGet, virtualScreenSizeX, 78
SysGet, virtualScreenSizeY, 79
if ((virtualScreenSizeX > 0) and (virtualScreenSizeY > 0))	; virtualScreenSize doesn't exist on NT and Win95
{
	WinGetPos, psLobbyPosX, psLobbyPosY, , , PokerStars Lobby - ahk_class #32770
	virtualScreenSizeX += 100
	virtualScreenSizeY += 100
	WinMove, PokerStars Lobby - ahk_class #32770, , %virtualScreenSizeX%, %virtualScreenSizeY%
	GuiControl, Enable, Show Lobby
}
return

NukeLobbies:
GroupAdd, TLobbies, Tournament ahk_class #32770, , , PokerStars Lobby
GroupClose, TLobbies, A
Return


; initiates registration process
; scrolls through the games list until an available game is found
; can register for several games
; TODO: check Register right before clicking the register button for max response time to buttonPause
registerForGame(times = 1) {
	global
	
	If TopReturn
		selectNextGame(true)
	while times > 0
	{
		times--
		If stopRegistering	; triggered by another thread (manually pausing or the timers for total games or total time)
		{
			setStatus(IDLE)
			break
		}
		ControlGet, registerButtonVisible, Visible, , %psRegisterButton%, PokerStars Lobby - ahk_class #32770
		If registerButtonVisible
		{
			ControlSend, %psRegisterButton%, {Space}, PokerStars Lobby - ahk_class #32770
			gosub, confirmRegistrationDialogs
			if returnFocus
				gosub, switchFocusToActiveGame
		}
		else
			If scrldwnEnabled
			{
				selectNextGame()
				times++
			}
		Sleep,500	; allow PS client to update its GUI (swapping the Register/Unregister buttons takes a moment)
	}
}

switchFocusToActiveGame:
; The 'Registered In Tournaments' dialog, if present, will steal focus, so we wait for that to happen
IfWinExist, Registered In Tournaments ahk_class #32770
	; times out after 3 seconds to avoid the unlikely event that the dialog exists but never gets focus
	WinWaitActive, Registered In Tournaments ahk_class #32770,, 3
; If there is at least one game running we switch focus to it
IfWinExist, ahk_class PokerStarsTableFrameClass
	WinActivate, ahk_class PokerStarsTableFrameClass
return

; called from registerForGame
; handles Buyin and Confirmation dialogs
; PS allows skipping the buyin dialog so we have three cases to consider:
; 1: Registration failed, no dialogs showing
; 2: both Buyin and Confirmation dialog show up
; 3: only Confirmation dialog is shown
; both dialogs have the same title, window class and 'OK' button class
; the buyin dialog in addition has a 'Register next if full' checkbox present
; this allows us to tell which dialog we are dealing with
; TODO: What happens if registration got declined because the game was already full?
confirmRegistrationDialogs:
WinWait, Tournament Registration ahk_class #32770, , 3
if (not ErrorLevel)	; if no dialog showed up we are done and skip the rest
{
	; now we check if this is the buyin dialog and if so click its 'OK' button
	ControlGet, regNextIfFullvisible, Visible, , Button2, Tournament Registration ahk_class #32770
	if regNextIfFullvisible
	{
		if AutoifFull
			ControlSend, Button2, {Space}, Tournament Registration ahk_class #32770
		ControlSend, PokerStarsButtonClass1, {Space}, Tournament Registration ahk_class #32770
	}
	; now we wait for and deal with the confirmation dialog
	WinWait, Tournament Registration ahk_class #32770, , 3
	if autoIfFull
		ControlSend, PokerStarsButtonClass2, {Space}, Tournament Registration ahk_class #32770
	else
		ControlSend, PokerStarsButtonClass1, {Space}, Tournament Registration ahk_class #32770
}
return

; moves the selection in the games list up or down
; keeps track of the direction internally
; call with reset=true to move selection to the first game in the list
selectNextGame(reset = false)
{
	global
	static ClickdirectionCount := 0
	static direction := "Down"
	
	if reset
	{
		ControlSend, %psGamesList%, {PGUP %scrlDwn%}, PokerStars Lobby - ahk_class #32770	; TODO find a proper way to select first game
		ClickdirectionCount := 0
		direction := "Down"
		return
	}
	
	If (ClickdirectionCount < scrldwn)
	{
		ControlSend, %psGamesList%, {%direction%}, PokerStars Lobby - ahk_class #32770
		ClickdirectionCount++
	}
	Else
	{
		direction := direction == "Down" ? "Up" : "Down"	; flip direction between "Up" and "Down"
		ClickdirectionCount := 0
	}
}
; uses PS logfile to count how many games are running and registered for
; if mode == 1 it will check the full logfile
; if mode == 0 it only checks lines appended since the last call to countTourneys()
; updates RegSoFar (total number of games registered)
CountTourneys(mode=0) {
	global logfile, RegSofar,tables
	static regtourneys := ""
	
	if mode=0
		log := CheckFile(logfile)
	else
		log := CheckFile(logfile,1)
	Loop, Parse, log, `n,
	{
		tnumber =
		tFrame := instr(A_loopField,"TournFrame")
		tColon := instr(A_loopField,"::")
		tTilde := instr(A_loopField,"~")
		tRTadd := instr(A_loopField,"RT add")
		If ( tFrame && !tColon && !tTilde ) || tRTadd
		{
			if tFrame
			{
				tnumber:=RegExReplace(A_loopField, "TournFrame '", "")
				stringleft,tnumber,tnumber,instr(tnumber,A_space)-2
			}
			else
			if tRTadd
			{
				tnumber:=RegExReplace(A_loopField, "RT add ", "")
				if instr(tnumber,A_space)
					StringLeft, tnumber, tnumber, instr(tnumber,A_space)-1
			}
			tnumber:=RegExReplace(tnumber, "[`n,`r]", "")
			if not instr(tables,tnumber)
				listadd(tables,tnumber)
		}
		else
		{
			tRTremove := instr(A_loopField,"RT remove")
			tTildeFrame := instr(A_loopField,"~TournFrame")
			If (tRTremove || tTildeFrame)
			{
				if tTildeFrame
				{
					tnumber:=RegExReplace(A_loopField, "~TournFrame '", "")
					stringleft,tnumber,tnumber,instr(tnumber,A_space)-2
				}
				else
					if tRTremove
						stringtrimleft,tnumber,A_loopField,instr(A_loopField,A_space,"",0)
				tnumber:=RegExReplace(tnumber, "[`n,`r]", "")
				if instr(tables,tnumber)
					listDelItem(tables,tnumber)
			}
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
