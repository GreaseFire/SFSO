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
