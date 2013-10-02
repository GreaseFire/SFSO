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

sfsoVersion = 4.3.0	; Used for the GUI Title and to migrate settings
debug := false		; if true SFSO saves its settings in the working dir and enables Hotkeys for reload and ListVars at the bottom of the script
#NoEnv
#SingleInstance, Force
SendMode Input
SetWorkingDir %A_ScriptDir%
;~ #Warn
;~ #Warn, LocalSameAsGlobal, Off
SetBatchLines, -1
SetTitleMatchMode, RegEx	; necessary to properly catch PS filter window (PSFilterManager.ahk)


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
	welcomeText .= "`tFILTER YOUR POKERSTARS LOBBY FOR`n"
	welcomeText .= "`tONLY THOSE GAMES YOU INTEND TO PLAY`n`n"
	welcomeText .= "Please refer to the readme for further details and explanation of the settings available."
	MsgBox, 4096, Welcome to Stars Filtered SNG Opener (SFSO), %welcomeText%
	IniWrite, 0, %sfsoSettingsFolder%\SFSO.ini, Settings, firstRun
	welcomeText =
}
goSub, requestAdminRights
goSub, setPSLogFilePath
SetTimer, checkPSVersion
gamesFinished := 0
GroupAdd, TLobbies, %PS_TOURNEY_LOBBY% ahk_class %PS_CLASS%

Gosub, BuildGui
Return
;==============================================================
#Include GUI_main.ahk
#Include GUI_IDTool.ahk
#Include GUI_options.ahk
#Include settings.ahk
#Include utility.ahk
#Include PSLogfileBroker.ahk
#Include hotkeys.ahk
#Include PSFilterManager.ahk
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

resetStatus()
displayedTime =
PausedTime := LimitTime
lastRegistration := 0
Gosub, setCountDown
interval := RegisterInterval*1000
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



ButtonResume:
SetTimer, updateWhilePaused, Off
Gui, Submit, NoHide
GuiControl, Disable, Resume
GuiControl, Enable, Pause
if LimitTimeEnabled
	if PausedTime is Number
		LimitTime := PausedTime
Gosub, setCountDown
If guardtimerEnabled
{
	killtime := guardtimer*60000
	SetTimer, deadManSwitch, 1000
}
Else
	SetTimer, deadManSwitch, off
stopRegistering := false
gamesWaiting := 0
gamesRunning := 0
tables=
waitForSetFinish := false
if (totalLimitEnabled and (keepOpen > totalLimit))
	keepOpen := totalLimit	; ensure totalLimit is obeyed even if keepOpen is higher than totalLimit 
updateTourneyCount(false)
if minLob
	gosub, moveLobby
SetTimer, Register, 1000
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
SetTimer, deadManSwitch, off
GuiControl, Disable, Pause
GuiControl, Enable, Resume
if minLob
	gosub, buttonShowLobby
setStatus(MANUAL_PAUSE)
SetTimer, updateWhilePaused, 1000
Return

; called from a timer whose frequency is determined by RegisterInterval
; checks how many games are open/waiting
; determines if any more games need to be registered
; if yes it will register for either:
;	one game and then return
;	as many games as currently needed (if batch register is enabled)
; TODO refactor condition checks into subroutines calling Exit if condition not met
Register:
;WinGet, LobbyID, id, %PS_LOBBY_LOGGED_IN% ahk_class %PS_CLASS%	; TODO: notify user to log into PS, atm SFSO shows 'Lobby not found'
IfWinNotExist, %PS_LOBBY_LOGGED_IN% ahk_class %PS_CLASS%
{
	Gosub, ButtonPause
	setStatus(LOBBY_NOT_FOUND)
	Return
}
ControlGet, SNGFilterButtonVisible, Visible, , %psShowFilterButton%, %PS_LOBBY_LOGGED_IN% ahk_class %PS_CLASS%
if (not SNGFilterButtonVisible)
{
	setStatus(NOT_IN_SNG_LOBBBY)
	return
}

 IfWinExist, %PS_REGISTER_DIALOG% ahk_class %PS_CLASS%	; under heavy load a registration might get interrupted leaving one of the dialogs open
	WinClose, %PS_REGISTER_DIALOG% ahk_class %PS_CLASS%	; if that happened on the last pass we close it now

updateTourneyCount()
if (waitForRematch and WinExist(PS_REMATCH_DIALOG . " ahk_class " . PS_CLASS))
{
	setStatus(WAITING_FOR_REMATCH)
	return
}
If (totalLimitEnabled and (RegSofar >= TotalLimit or OpenTables >= TotalLimit)) ; assert openTables <= regSoFar -> second part should not matter
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
;~ sanityCheck()
if ((lastRegistration + interval) > A_TickCount)	; if %registerInterval% seconds have not passed yet we are done on this pass
	return ; TODO prevents timely status updates 
; at this point we are ready to register for another game
if learning
{
	scrldwn := gamesWaiting + 1
}
; assert 0 < scrldwn <= availableGames + 1
; assert gamesWaiting < scrldwn
if (scrldwn < gamesWaiting)
{
	; assert learning == false
	; assert gamesWaiting == availableGames
	; no game available for registration, have to wait for a game to start
	setStatus(NO_GAMES_AVAILABLE)
	return
}

setStatus(REGISTERING)
registerForGame()
If (BatchReg and (openTables == 0 or learning))	; TODO count running games and compare to that
	lastRegistration := 0	; causes the next pass of this timer to register as well 
else
	lastRegistration := A_TickCount ; once there is 1+ game running (or if batchReg is off) we switch to obeying registerInterval
Return


; no good - fails when a game finishes (gamesRunning is updated before a table window is destroyed)
;~ ; compares the tablecount from the logfile to the current number of open tourney tables a retrieved by WinGet
;~ ; this check will trigger if we somehow use the wrong logfile
;~ sanityCheck()
;~ {
	;~ global
	;~ WinGet, physicalTables, Count, %PS_TOURNEY_WINDOW% ahk_class %PS_GAME_CLASS%
	;~ ; since gamesRunning counts any Tournament Table opened it should never be lower than physicalTables
	;~ ; additionally physicalTables is not updated as fast as gamesRunning
	;~ ; so having more physical than counted tables means either:
	;~ ;	- user has one or more cash games running
	;~ ;	- we use the wrong logfile
	;~ ; Since the latter spells pretty much Doom for us we go into panic mode:
	;~ ;	- disable all timers
	;~ ;	- disable all controls
	;~ ;	- give out a error message
	;~ ;	- pause the script
	;~ if (physicalTables > gamesRunning)
	;~ {
		;~ SetTimer, Countdown, off
		;~ SetTimer, Register, off
		;~ SetTimer, deadManSwitch, off
		;~ setStatus(GAMECOUNT_MISMATCH)
		;~ Gui, +Disabled
		;~ MsgBox, 8208, SFSO, Internal count of games running does not match detected number of open tables. SFSO has been disabled.
		;~ Pause
		;~ Exit	; if the user manually unpauses we immediately leave the current thread (usually the register one)
	;~ }
;~ }

; searches and registers for a valid game
; handles the confirmation dialogs
; can return focus to game table
registerForGame() {
	global
	
	If stopRegistering	; triggered by another thread (manually pausing or the timers for total games or total time)
	{
		setStatus(IDLE)
		return
	}
	if (selectNextGame(TopReturn) and not stopRegistering)
	{
		ControlSend, %psRegisterButton%, {Space}, %PS_LOBBY_LOGGED_IN% ahk_class %PS_CLASS%
		gosub, confirmRegistrationDialogs
		if returnFocus
			gosub, switchFocusToActiveGame
	}
}

switchFocusToActiveGame:
; The 'Registered In Tournaments' dialog, if present, will steal focus, so we wait for that to happen
IfWinExist, %PS_REGISTERED_IN% ahk_class %PS_CLASS%
	; times out after 5 seconds to avoid the unlikely event that the dialog exists but never gets focus
	WinWaitActive, %PS_REGISTERED_IN% ahk_class %PS_CLASS%,, 5
; If there is at least one game running we switch focus to it
IfWinExist, ahk_class %PS_GAME_CLASS%
	WinActivate, ahk_class %PS_GAME_CLASS%
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
WinWait, %PS_REGISTER_DIALOG% ahk_class %PS_CLASS%, , 5
if (not ErrorLevel)	; if no dialog showed up we are done and skip the rest
{
	; now we check if this is the buyin dialog and if so click its 'OK' button
	ControlGet, regNextIfFullvisible, Visible, , Button2, %PS_REGISTER_DIALOG% ahk_class %PS_CLASS%
	if regNextIfFullvisible
	{
		if AutoifFull
			ControlSend, Button2, {Space}, %PS_REGISTER_DIALOG% ahk_class %PS_CLASS%
		ControlSend, PokerStarsButtonClass1, {Space}, %PS_REGISTER_DIALOG% ahk_class %PS_CLASS%
	}
	; now we wait for and deal with the confirmation dialog
	WinWait, %PS_REGISTER_DIALOG% ahk_class %PS_CLASS%, , 5
	if autoIfFull
		ControlSend, PokerStarsButtonClass2, {Space}, %PS_REGISTER_DIALOG% ahk_class %PS_CLASS%
	else
		ControlSend, PokerStarsButtonClass1, {Space}, %PS_REGISTER_DIALOG% ahk_class %PS_CLASS%
}
return

; scrolls through the games list until an available game is found
; moves the selection in the games list up or down
; keeps track of the direction internally
; call with reset=true to move selection to the first game in the list
; returns true if a game available for registration has been found/selected, false otherwise
selectNextGame(startFromTop = false)
{
	global
	static direction := "Down"
	
	if startFromTop
	{
		ControlSend, %psGamesList%, {PGUP 10}, %PS_LOBBY_LOGGED_IN% ahk_class %PS_CLASS%	; TODO find a proper way to select first game
		direction := "Down"
	}
	count := scrlDwn * 2
	count := (count == 0 ? 1 : count) ; ensure we loop at least one time
	Loop %count%
	{
		ControlGet, registerButtonVisible, Visible, , %psRegisterButton%, %PS_LOBBY_LOGGED_IN% ahk_class %PS_CLASS%
		If registerButtonVisible
			return true
		ControlSend, %psGamesList%, {%direction%}, %PS_LOBBY_LOGGED_IN% ahk_class %PS_CLASS%
		Sleep,300	; allow PS client to update its GUI (swapping the Register/Unregister buttons takes a moment)
		if (A_Index == scrlDwn)
			direction := (direction == "Down" ? "Up" : "Down")	; flip direction between "Up" and "Down"
	}
	; assert availableGames == scrldwn + 1
	; if we reach this point we know that:
	;	all available Games are registered for
	;	correct scrlDwn = current scrlDwn - 2 because scrlDwn was set to registered games + 1
	;	we found the correct (max) value for scrlDwn
	; Example:
	; There are 4 games in the list and all are registered for. scrlDwn is then set to 5.
	; The correct value is 3.
	; both scrlDwn and learning are reset when the active Filter changes
	; this keeps the need for relearning to the abslotute minimum
	if learning
	{
		learning := false
		scrlDwn -= 2
	}
	return false
}


; uses PS logfile to count how many games are running and registered for
; in its normal mode (sessionUpdate == true) it will parse only recently added lines from the logfile
; calling updateTourneyCount(false) will reset the below counters (except gamesFinished) and parse the full logfile
; updates these global variables:
;	RegSoFar		(number of games registered on this run)
;	gamesFinished	(number of games registered since program start)
;	openTables		(number of running and registered games)
; 	gamesWaiting	(number of registered games only)
; searches for:
;	'RT add'		new game registered
;	'RT shown'		new game started
;	'RT remove'		either a game has finished or been unregistered
; games without a 'RT add' line present are skipped (happens when PS client deleted the logfile while
;	a game was registered/running - either way we got nothing to do with it)
; as backup to the RT lines it also searches for:
;	TournFrame		new tournament window created
;	~TournFrame		tournament window closed
; these become interesting in exceptional situations (exiting out of an unfinished game for example causes that game to remain counted as registered)
; on a full pass (usually at session start) also checks PokerStars.log.1 (yesterdays backup log)
; 	to account for games registered/started before and finished after midnight
updateTourneyCount(sessionUpdate = true) {
	global 
	static regtourneys := ""
	static waitList := ""
	local logLines := ""
	local tcount := 0
	local tnumber := ""
	local found := ""
	
	if sessionUpdate
		logLines := CheckFile(logfile)
	else	; prepare (reset) for starting a new run
	{
		FileGetSize, size0, logfile
		FileGetSize, size1, backuplog
		VarSetCapacity(logLines, size0 + size1)
		logLines := checkFile(backupLog, 1) ; get yesterdays log
		;~ logLines := CheckFile(logfile,1)	; append todays log
		logLines .= CheckFile(logfile,1)	; append todays log
		regSoFar := 0
		gamesWaiting := 0
		gamesRunning := 0
		openTables := 0
		regtourneys := ""
		waitList := ""
	}
	
	Loop, Parse, logLines, `r`n,
	{
		If (InStr(A_LoopField, "RT ", true))
		{
			StringSplit, line, A_LoopField, %A_Space%
			
			if (line2 == "add")
			{
				if (setAdd(waitList, line3))
					gamesWaiting++
				continue
			}
			if (line2 == "shown")
			{
				if (setAdd(tables,line3))
					gamesRunning++
				If (setRemove(waitList, line3))
					gamesWaiting--
				continue
			}
			if (line2 == "remove")
			{
				if (setRemove(tables,line3))
					gamesRunning--
				If (setRemove(waitList, line3))	; triggers when unregistering a game
					gamesWaiting--
				continue
			}
		}
		if (InStr(A_LoopField, "TournFrame '", true))
		{
			StringSplit, line, A_LoopField, '
			if (line1 == "TournFrame ")
			{
				if (setAdd(tables, line2))
					gamesRunning++
				If (setRemove(waitList, line2))
					gamesWaiting--
				continue
			}
			if (line1 == "~TournFrame ")
			{
				if (setRemove(tables, line2))
					gamesRunning--
				If (setRemove(waitList, line2))
					gamesWaiting--
				continue
			}
		}
	}
	if sessionUpdate
	{
		Loop, Parse, tables, -,
		{
			if (setAdd(regtourneys,A_LoopField))
			{
				RegSofar++
				gamesFinished++
			}
		}
	}
	openTables := gamesRunning + gamesWaiting
	setStatus()	; update info area
}


;~ updateTourneyCount(sessionUpdate = true) {
	;~ global logfile, RegSofar, tables, openTables, gamesFinished, gamesWaiting
	;~ static regtourneys := ""
	;~ static waitList := ""
	;~ logLines := ""
	;~ found := ""
	
	;~ if sessionUpdate
		;~ logLines := CheckFile(logfile)
	;~ else	; prepare (reset) for starting a new run
	;~ {
		;~ logLines := CheckFile(logfile,1)
		;~ regSoFar := 0
		;~ gamesWaiting := 0
		;~ openTables := 0
		;~ regtourneys := ""
		;~ waitList := ""
	;~ }
	;~ Loop, Parse, logLines, `r`n,
	;~ {
		;~ If (InStr(A_LoopField, "RT ", true))
		;~ {
			;~ gameNumber := RegExReplace(A_LoopField, "AS)RT shown (\d+)", "$1", found)
			;~ if found
			;~ {
				;~ If (setRemove(waitList, gameNumber))
					;~ gamesWaiting--
				;~ continue
			;~ }
			;~ gameNumber := RegExReplace(A_LoopField, "AS)RT remove (\d+)", "$1", found)
			;~ if found
			;~ {
				;~ if (setRemove(tables,gameNumber))
					;~ openTables--
				;~ If (setRemove(waitList, gameNumber))	; triggers when unregistering a game
					;~ gamesWaiting--
				;~ continue
			;~ }
			;~ gameNumber := RegExReplace(A_LoopField, "AS)RT add (\d+).+$", "$1", found)
			;~ if found
			;~ {
				;~ if (setAdd(tables,gameNumber))
				;~ {
					;~ if (setAdd(waitList, gameNumber))
						;~ gamesWaiting++
					;~ openTables++
				;~ }
				;~ continue
			;~ }
		;~ }
	;~ }
	;~ if sessionUpdate
	;~ {
		;~ Loop, Parse, tables, -,
		;~ {
			;~ if (setAdd(regtourneys,A_LoopField))
			;~ {
				;~ RegSofar++
				;~ gamesFinished++
			;~ }
		;~ }
	;~ }
	;~ setStatus()	; update info area
;~ }


NukeLobbies:
GroupClose, TLobbies, A
Return


deadManSwitch:
If (A_TimeIdle > killtime)
{
	Gosub, ButtonPause
	setStatus(USER_INACTIVE)
}
Return


setCountDown:
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


; called from a timer after ButtonPause has triggered
; keeps updating the Tables open/waiting counter until either:
;	- all games are finished
; 	- auto registering resumes/starts via ButtonResume
; TODO with register running at a 1s interval this timer is kinda obsolete
updateWhilePaused:
Critical
updateTourneyCount()
if (openTables == 0)
	SetTimer, updateWhilePaused, Off
return


moveLobby:
SysGet, virtualScreenSizeX, 78
SysGet, virtualScreenSizeY, 79
if ((virtualScreenSizeX > 0) and (virtualScreenSizeY > 0))	; virtualScreenSize doesn't exist on NT and Win95
{
	WinGetPos, psLobbyPosX, psLobbyPosY, , , %PS_LOBBY_LOGGED_IN% ahk_class %PS_CLASS%
	virtualScreenSizeX += 100
	virtualScreenSizeY += 100
	WinMove, %PS_LOBBY_LOGGED_IN% ahk_class %PS_CLASS%, , %virtualScreenSizeX%, %virtualScreenSizeY%
	GuiControl, Enable, Show Lobby
}
return

