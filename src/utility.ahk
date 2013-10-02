
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

; called after the GUI window has been moved
; see http://msdn.microsoft.com/en-us/library/windows/desktop/ms632623(v=vs.85).aspx
WM_EXITSIZEMOVE()
{
	global
	IfWinExist, ahk_id %mainGuiId%	; WM_EXITSIZEMOVE gets called at least once before the main GUI is shown at which point WinGetPos would fail
		WinGetPos, GuiScreenPosX, GuiScreenPosY, , , ahk_id %mainGuiId%
	return 0
}

listAdd( byRef list, item) {
	static  del := "-"
  list:=( list!="" ? ( list . del . item ) : item )
  return list
}

listDelItem( byRef list, item) {
	static  del := "-"
	ifEqual, item,, return list
	list:=del . list . del
	StringReplace, list, list, %item%%del%
	StringTrimLeft, list, list, 1
	StringTrimRight, list, list, 1
	return list
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
	WinMenuSelectItem, PokerStars Lobby,, Requests, Transfer Funds, Transfer to another player...
	WinWait, Transfer Funds ahk_class #32770, , 10
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
