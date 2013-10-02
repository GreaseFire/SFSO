; written for AHK build 1.0.45.4
; ensures SFSO is run with AHK_L (ANSI 32-bit) build 1.1.13.00 or higher

if A_AhkVersion < 1.1.13.00
	MsgBox, 4112, SFSO, SFSO requires  AutoHokey_L  (ANSI 32-bit)  v1.1.13.00  or higher.
else
	if A_IsUnicode
		MsgBox, 4112, SFSO, SFSO requires the ANSI (32-bit) installation of AutoHotkey_L.`nPlease rerun the AutoHotkey setup. SFSO will now exit.
	else
		Run, main.ahk, %A_ScriptDir%\src
ExitApp