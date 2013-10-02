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

initGlobalVars:
RegSofar := 0
gamesWaiting := 0
gamesRunning := 0
gamesFinished := 0
waitForSetFinish := false

psCurrentVersion := "7.1.2.5"	; usually overwritten by checkPSVersion unless SFSO exits before PS client is running

; variables below this line are understood to be read only constants ---> Do not change them anywhere else!
; use these for windowing commands (WinWait, WinGet, ...)
; all criteria are formulated as regular expressions
; try to formulate them as restrictive as possible (e.g. ahk_class PS_CLASS will behave like ahk_class #32770 with A_TitleMatchMode == 1)
; 	Keep in mind that only very little text is the same when PS client is set to a language other than English
;	The main window for example retains only "PokerStars" in its title (when logged in it will also have a "-" and the username) with 
;		several localized Strings inbetween.
; 	Do not include ahk_class or ahk_id etc.
; TODO crack I18n.txt in ps program folder to use as base for these values
PS_CLASS := "^#32770$"
PS_GAME_CLASS := "^PokerStarsTableFrameClass$"

PS_LOBBY := "^PokerStars Lobby"
PS_LOBBY_LOGGED_IN := "^PokerStars Lobby - Logged in"
PS_REGISTER_DIALOG := "^Tournament Registration$"
PS_FILTER_WINDOW := "^$"
PS_TOURNEY_LOBBY := "^Tournament \d+ Lobby$"
PS_TOURNEY_WINDOW := ".*Tournament \d+ .*"
PS_REMATCH_DIALOG := "^Tournament Rematch$"
PS_REGISTERED_IN := "^Registered In Tournaments$"
PS_TRANSFER := "^Transfer Funds$"

; the variables below are used for updating the status area of the main window
GAMECOUNT_MISMATCH  := 1
WAITING := 2
REGISTERING := 3
IDLE := 4
SET_FULL := 5
TOTAL_LIMIT_REACHED := 6
WAITING_FOR_REMATCH := 7
LOBBY_NOT_FOUND := 8
MANUAL_PAUSE := 9
TIME_LIMIT_REACHED := 10
REMAINING_TIME := 11
NOT_IN_SNG_LOBBBY := 12
USER_INACTIVE := 13
NO_GAMES_AVAILABLE := 14
return

; NEVER load a setting without providing a default!
;	Without a default iniRead sets the var to "ERROR"
;	Earlier versions had a corrupted GUI showing on first run because of this
; Where applicable choose defaults suitable for testing on play money
loadSettings:
IniRead, sfsoSettingsVersion, %sfsoSettingsFolder%\SFSO.ini, Settings, sfsoSettingsVersion	, 4.1	; not present in 4.1 which was first to save in AppData
if (sfsoSettingsVersion == "4.1")				; most Advanced Settings were still broken in 4.1 so to avoid confusion and unexpected behaviour
{
	FileDelete, %sfsoSettingsFolder%\SFSO.ini	; its better to start off fresh (annoying as it is)
	sfsoSettingsVersion := sfsoVersion			; TODO adapt for future versions
}
IniRead, firstRun			, %sfsoSettingsFolder%\SFSO.ini, Settings, firstRun				, 1
IniRead, AutoIfFull			, %sfsoSettingsFolder%\SFSO.ini, Settings, AutoIfFull			, 0
IniRead, TopReturn			, %sfsoSettingsFolder%\SFSO.ini, Settings, TopReturn			, 0
IniRead, BatchReg			, %sfsoSettingsFolder%\SFSO.ini, Settings, BatchReg				, 1
IniRead, SetReg				, %sfsoSettingsFolder%\SFSO.ini, Settings, SetReg				, 1
IniRead, MinLob				, %sfsoSettingsFolder%\SFSO.ini, Settings, MinLob				, 0
IniRead, GuiScreenPosX		, %sfsoSettingsFolder%\SFSO.ini, Settings, GuiScreenPosX		, 10
IniRead, GuiScreenPosY		, %sfsoSettingsFolder%\SFSO.ini, Settings, GuiScreenPosY		, 10
IniRead, requestElevation	, %sfsoSettingsFolder%\SFSO.ini, Settings, requestElevation		, ask
IniRead, CloseInterv		, %sfsoSettingsFolder%\SFSO.ini, Settings, CloseInterv			, 30
IniRead, CloseIntervEnabled	, %sfsoSettingsFolder%\SFSO.ini, Settings, CloseIntervEnabled	, 0
IniRead, GuardTimer			, %sfsoSettingsFolder%\SFSO.ini, Settings, GuardTimer			, 3
IniRead, GuardTimerEnabled	, %sfsoSettingsFolder%\SFSO.ini, Settings, GuardTimerEnabled	, 1
IniRead, ReturnFocus		, %sfsoSettingsFolder%\SFSO.ini, Settings, ReturnFocus			, 1
IniRead, CloseInterv		, %sfsoSettingsFolder%\SFSO.ini, Settings, CloseInterv			, 30
IniRead, CloseIntervEnabled	, %sfsoSettingsFolder%\SFSO.ini, Settings, CloseIntervEnabled	, 0
IniRead, waitForRematch		, %sfsoSettingsFolder%\SFSO.ini, Settings, waitForRematch		, 1

IniRead, psSettingsFolder		, %sfsoSettingsFolder%\SFSO.ini, Settings, psSettingsFolder		, 
IniRead, psLastKnownVersion		, %sfsoSettingsFolder%\SFSO.ini, Settings, psLastKnownVersion	, 7.2.3.9
IniRead, psRegisterButton		, %sfsoSettingsFolder%\SFSO.ini, Settings, psRegisterButton		, PokerStarsButtonClass10
IniRead, psGamesList			, %sfsoSettingsFolder%\SFSO.ini, Settings, psGamesList			, PokerStarsListClass3

IniRead, psShowFilterButton		, %sfsoSettingsFolder%\SFSO.ini, Settings, psShowFilterButton	, PokerStarsButtonClass33
IniRead, psEnableFilterButton	, %sfsoSettingsFolder%\SFSO.ini, Settings, psEnableFilterButton	, PokerStarsButtonClass34
IniRead, psCloseFilterButton	, %sfsoSettingsFolder%\SFSO.ini, Settings, psCloseFilterButton	, PokerStarsButtonClass5
IniRead, psResetFilterButton	, %sfsoSettingsFolder%\SFSO.ini, Settings, psResetFilterButton	, PokerStarsButtonClass2

return


saveSettings:
IniWrite, %sfsoSettingsVersion%	, %sfsoSettingsFolder%\SFSO.ini, Settings, sfsoSettingsVersion
IniWrite, %CloseInterv%			, %sfsoSettingsFolder%\SFSO.ini, Settings, CloseInterv
IniWrite, %CloseIntervEnabled%	, %sfsoSettingsFolder%\SFSO.ini, Settings, CloseIntervEnabled
IniWrite, %AutoIfFull%			, %sfsoSettingsFolder%\SFSO.ini, Settings, AutoIfFull
IniWrite, %TopReturn%			, %sfsoSettingsFolder%\SFSO.ini, Settings, TopReturn
IniWrite, %BatchReg%			, %sfsoSettingsFolder%\SFSO.ini, Settings, BatchReg
IniWrite, %Setreg%				, %sfsoSettingsFolder%\SFSO.ini, Settings, SetReg
IniWrite, %Minlob%				, %sfsoSettingsFolder%\SFSO.ini, Settings, MinLob
IniWrite, %GuardTimer%			, %sfsoSettingsFolder%\SFSO.ini, Settings, GuardTimer
IniWrite, %GuardTimerEnabled%	, %sfsoSettingsFolder%\SFSO.ini, Settings, GuardTimerEnabled
IniWrite, %GuiScreenPosX%		, %sfsoSettingsFolder%\SFSO.ini, Settings, GuiScreenPosX
IniWrite, %GuiScreenPosY%		, %sfsoSettingsFolder%\SFSO.ini, Settings, GuiScreenPosY
IniWrite, %requestElevation%	, %sfsoSettingsFolder%\SFSO.ini, Settings, requestElevation
IniWrite, %psRegisterButton%	, %sfsoSettingsFolder%\SFSO.ini, Settings, psRegisterButton
IniWrite, %psGamesList%			, %sfsoSettingsFolder%\SFSO.ini, Settings, psGamesList
IniWrite, %ReturnFocus%			, %sfsoSettingsFolder%\SFSO.ini, Settings, ReturnFocus
IniWrite, %waitForRematch%		, %sfsoSettingsFolder%\SFSO.ini, Settings, waitForRematch

IniWrite, %psCurrentVersion%	, %sfsoSettingsFolder%\SFSO.ini, Settings, psLastKnownVersion
Return
