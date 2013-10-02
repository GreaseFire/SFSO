
; TODO: check integrity level of PS client first and only elevate script if necessary
;	See http://msdn.microsoft.com/en-us/library/bb625966.aspx
requestAdminRights:
if (requestElevation == "ask" and not A_IsAdmin)	;no point in asking if SFSO is already running as admin
{	; SFSO only needs Admin rights if PS is running elevated hence we be nice and ask first
	MsgBox, 4100,, Do you run PokerStars as Administrator? (You can change this later on the 'Advanced' tab)
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

; run from a timer at program start
; anything depending on PS client running goes in here
establishConnectionToPSclient:
; check version
; set logfile path
; set filter

; enable gui controls
return

; gets called by a Timer until PS client is running
; checks if the client got updated and if so displays a reminder for the ID Tool
checkPSVersion:
ifWinExist %PS_LOBBY% ahk_class %PS_CLASS%
{
	SetTimer, checkPSVersion, Off
	WinGet, psExePath, ProcessPath
	FileGetVersion, psCurrentVersion, %psExePath%
	if (psCurrentVersion != psLastKnownVersion)
		MsgBox,, PokerStars update detected, If SFSO is not registering for games use the "Identify PS controls" tool from the advanced tab
			. You might also have to use the tool if you change your Lobby theme.
}
return

; listAdd and listDelItem were referring to wrong concept. What we really want is a set.
; adds item to set
; returns true if set changed, false otherwise
setAdd( byRef set, item) {
	static  del := "-"
	if not instr(set,item)
	{
		set := ( set == "" ? item : ( set . del . item ))
		return true
	}
	return false
}
; removes item from set
; returns true if set changed, false otherwise
setRemove( byRef set, item) {
	static  del := "-"
	ifEqual, item,, return
	if instr(set,item)
	{
		set := del . set . del
		StringReplace, set, set, %item%%del%
		StringTrimLeft, set, set, 1
		StringTrimRight, set, set, 1
		return true
	}
	return false
}

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
		StringTrimLeft, _val, _val, 1
	StringTrimRight, FirstZ, _val, 1
	If FirstZ=0
		StringTrimLeft, _val, _val, 1
	Return _val
}

donation() {
	global
	WinMenuSelectItem, %PS_LOBBY_LOGGED_IN%,, Requests, Transfer Funds, Transfer to another player...
	WinWait, %PS_TRANSFER% ahk_class %PS_CLASS%, , 10
	if not ErrorLevel
	{
		WinGet, tf, id
		ControlFocus, Edit2, ahk_id%tf%
		ControlSetText, Edit2, Local0
		ControlFocus, Edit1, ahk_id%tf%
		Sleep, -1
		ControlSetText, Edit1,
		GuiControl, Disable, Donate
	}
}

logwrite(line)
{
	Critical
	static log := getStaticLog()

	FormatTime, time, A_Now, [MM/dd HH:mm:ss]
	log.write(time . "`t" . line . "`n")
}

; called once from logwrite when initializing static variables
getStaticLog()
{
	static done
	if done
		return
	else done := true
	FileGetSize, size, %A_Temp%\SFSO.log.txt, M
	if (size >= 10)
		FileMove, %A_Temp%\SFSO.log.txt, %A_Temp%\SFSO.log.old.txt, 1	; create backup of previous logfile
	return FileOpen(A_Temp . "\SFSO.log.txt", "a-wd`n") ; keep the logfile open between calls, locked against external writes or deletes
}