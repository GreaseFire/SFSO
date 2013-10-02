showIDTool:
Gui, +Disabled	; disable the main window
Gui, idTool:+Owner -MinimizeBox +ToolWindow
Gui, idTool:Add, Text,, Identify the following controls in the`nPokerStars client by right clicking on them:

Gui, idTool:Add, Text, Section	, Tourney List:
Gui, idTool:Add, Text,		, Register Button:

Gui, idTool:Add, Edit, ys w130 ReadOnly vPSGamesList		; no defaults for the edit boxes to provide visual clues for successful selection
Gui, idTool:Add, Edit,    w130 ReadOnly vPSRegisterButton

Gui, idTool:Add, Button, Section vIdToolOK disabled	, OK		; vIdToolOK only provides a reference to allow enabling the button later on
Gui, idTool:Add, Button, ys				, Cancel

WinActivate, PokerStars Lobby ahk_class #32770

x := GuiScreenPosX + 30
y := GuiScreenPosY + 30
Gui, idTool:Show, x%X% y%Y%, SFSO ID Tool

buttonSelected := false
listSelected := false
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
