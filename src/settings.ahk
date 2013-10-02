initGlobalVars:
RegSofar=0
OpenTables=0
waitForSetFinish := false

psCurrentVersion := "7.1.2.5"	; usually overwritten by checkPSVersion unless SFSO exits before PS client is running

; the variables below are used for updating the status area of the main window
; do not change them anywhere else!
;TABLES := 1
WAITING := 2
REGISTERING := 3
IDLE := 4
SET_FULL := 5
TOTAL_LIMIT_REACHED := 6
LOBBY_NOT_FOUND := 8
MANUAL_PAUSE := 9
TIME_LIMIT_REACHED := 10
REMAINING_TIME := 11
TIME_LIMIT_OFF := 12
USER_INACTIVE := 13
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
IniRead, RegisterInterval	, %sfsoSettingsFolder%\SFSO.ini, Settings, RegisterInterval		, 20
IniRead, KeepOpen			, %sfsoSettingsFolder%\SFSO.ini, Settings, KeepOpen				, 3
IniRead, TotalLimit			, %sfsoSettingsFolder%\SFSO.ini, Settings, TotalLimit			, 4
IniRead, TotalLimitEnabled	, %sfsoSettingsFolder%\SFSO.ini, Settings, TotalLimitEnabled	, 1
IniRead, LimitTime			, %sfsoSettingsFolder%\SFSO.ini, Settings, LimitTime			, 30
IniRead, LimitTimeEnabled	, %sfsoSettingsFolder%\SFSO.ini, Settings, LimitTimeEnabled		, 0
IniRead, GuiScreenPosX		, %sfsoSettingsFolder%\SFSO.ini, Settings, GuiScreenPosX		, 10
IniRead, GuiScreenPosY		, %sfsoSettingsFolder%\SFSO.ini, Settings, GuiScreenPosY		, 10
IniRead, requestElevation	, %sfsoSettingsFolder%\SFSO.ini, Settings, requestElevation		, ask
IniRead, psSettingsFolder	, %sfsoSettingsFolder%\SFSO.ini, Settings, psSettingsFolder		, ""
IniRead, psLastKnownVersion	, %sfsoSettingsFolder%\SFSO.ini, Settings, psLastKnownVersion	, 7.1.2.5
IniRead, psRegisterButton	, %sfsoSettingsFolder%\SFSO.ini, Settings, psRegisterButton		, PokerStarsButtonClass10
IniRead, psGamesList		, %sfsoSettingsFolder%\SFSO.ini, Settings, psGamesList			, PokerStarsListClass4
IniRead, scrldwn			, %sfsoSettingsFolder%\SFSO.ini, Settings, scrldwn				, 6
IniRead, scrldwnEnabled		, %sfsoSettingsFolder%\SFSO.ini, Settings, scrldwnEnabled		, 1
IniRead, CloseInterv		, %sfsoSettingsFolder%\SFSO.ini, Settings, CloseInterv			, 30
IniRead, CloseIntervEnabled	, %sfsoSettingsFolder%\SFSO.ini, Settings, CloseIntervEnabled	, 0
IniRead, GuardTimer			, %sfsoSettingsFolder%\SFSO.ini, Settings, GuardTimer			, 3
IniRead, GuardTimerEnabled	, %sfsoSettingsFolder%\SFSO.ini, Settings, GuardTimerEnabled	, 1
IniRead, ReturnFocus		, %sfsoSettingsFolder%\SFSO.ini, Settings, ReturnFocus			, 1
return


saveSettings:
IniWrite, %sfsoSettingsVersion%	, %sfsoSettingsFolder%\SFSO.ini, Settings, sfsoSettingsVersion
IniWrite, %AutoIfFull%			, %sfsoSettingsFolder%\SFSO.ini, Settings, AutoIfFull
IniWrite, %TopReturn%			, %sfsoSettingsFolder%\SFSO.ini, Settings, TopReturn
IniWrite, %scrldwn%				, %sfsoSettingsFolder%\SFSO.ini, Settings, scrldwn
IniWrite, %scrldwnEnabled%		, %sfsoSettingsFolder%\SFSO.ini, Settings, scrldwnEnabled
IniWrite, %BatchReg%			, %sfsoSettingsFolder%\SFSO.ini, Settings, BatchReg
IniWrite, %Setreg%				, %sfsoSettingsFolder%\SFSO.ini, Settings, SetReg
IniWrite, %Minlob%				, %sfsoSettingsFolder%\SFSO.ini, Settings, MinLob
IniWrite, %RegisterInterval%	, %sfsoSettingsFolder%\SFSO.ini, Settings, RegisterInterval
IniWrite, %CloseInterv%			, %sfsoSettingsFolder%\SFSO.ini, Settings, CloseInterv
IniWrite, %CloseIntervEnabled%	, %sfsoSettingsFolder%\SFSO.ini, Settings, CloseIntervEnabled
IniWrite, %KeepOpen%			, %sfsoSettingsFolder%\SFSO.ini, Settings, KeepOpen
IniWrite, %TotalLimit%			, %sfsoSettingsFolder%\SFSO.ini, Settings, TotalLimit
IniWrite, %TotalLimitEnabled%	, %sfsoSettingsFolder%\SFSO.ini, Settings, TotalLimitEnabled
IniWrite, %GuardTimer%			, %sfsoSettingsFolder%\SFSO.ini, Settings, GuardTimer
IniWrite, %GuardTimerEnabled%	, %sfsoSettingsFolder%\SFSO.ini, Settings, GuardTimerEnabled
IniWrite, %LimitTime%			, %sfsoSettingsFolder%\SFSO.ini, Settings, LimitTime
IniWrite, %LimitTimeEnabled%	, %sfsoSettingsFolder%\SFSO.ini, Settings, LimitTimeEnabled
IniWrite, %GuiScreenPosX%		, %sfsoSettingsFolder%\SFSO.ini, Settings, GuiScreenPosX
IniWrite, %GuiScreenPosY%		, %sfsoSettingsFolder%\SFSO.ini, Settings, GuiScreenPosY
IniWrite, %requestElevation%	, %sfsoSettingsFolder%\SFSO.ini, Settings, requestElevation
IniWrite, %psRegisterButton%	, %sfsoSettingsFolder%\SFSO.ini, Settings, psRegisterButton
IniWrite, %psGamesList%			, %sfsoSettingsFolder%\SFSO.ini, Settings, psGamesList
IniWrite, %ReturnFocus%			, %sfsoSettingsFolder%\SFSO.ini, Settings, ReturnFocus

IniWrite, %psCurrentVersion%	, %sfsoSettingsFolder%\SFSO.ini, Settings, psLastKnownVersion
Return
