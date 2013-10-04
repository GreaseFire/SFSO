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

showOptions:

Gui, +Disabled	; disable the main window
Gui, options:add, CheckBox,	y+14	Section	vGuardtimerEnabled	gSpinnersOnOff	Checked%GuardtimerEnabled%	, Disable if no user Input (min):
Gui, options:add, CheckBox,	y+14	r2		vCloseIntervEnabled	gSpinnersOnOff	Checked%CloseIntervEnabled%	, Close lobbies every (sec):`n(manually Close with Win+c)

Gui, options:add, Edit,		ys-3	w40		vGuardtimer						Number	Limit2				, %Guardtimer%
Gui, options:add, UpDown, 													Range1-15					, %Guardtimer%
Gui, options:add, Edit,				wp		vCloseInterv					Number	Limit3				, %CloseInterv%
Gui, options:add, UpDown, 						gUpDownCloseInterv			Range5-180					, %CloseInterv%

Gui, options:add, Checkbox, xs y+30			vSetReg							Checked%SetReg%				, Register in sets
Gui, options:add, Checkbox,					vBatchReg						Checked%BatchReg%			, Register with high frequency`nat session start
Gui, options:add, Checkbox, 				vReturnFocus					Checked%ReturnFocus%		, Activate open table after registering
Gui, options:add, Checkbox,					vTopReturn						Checked%TopReturn%			, Always start at top of lobby
Gui, options:add, Checkbox,					vMinLob							Checked%MinLob%				, Move lobby off screen`n(Failsafe: Win+Shift+Home)
Gui, options:add, Checkbox,					vAutoifFull						Checked%AutoIfFull%			, Register next if full
Gui, options:add, Checkbox,					vWaitForRematch					Checked%waitForRematch%		, Wait for rematch decision (Heads up)

Gui, options:add, Checkbox, 		r2		vrequestElevation 				Checked%requestElevation%	, Request Admin Privileges?`n(requires restart)

Gui, options:add, Button, gLaunchIDTool, Identify PS Controls
Gui, options:add, Button, gOpenSettingsFolder, Open SFSO Settings Folder

Gui, options:+Owner +ToolWindow

GuiControl, options:Enabled%GuardtimerEnabled%	, Guardtimer
GuiControl, options:Enabled%CloseIntervEnabled%	, CloseInterv

x := GuiScreenPosX + 30
y := GuiScreenPosY + 30
Gui, options:Show, x%X% y%Y%, SFSO Options
return

SpinnersOnOff:
Gui, options:Submit, NoHide
GuiControl, options:Enabled%GuardtimerEnabled%	, Guardtimer
GuiControl, options:Enabled%CloseIntervEnabled%	, CloseInterv
gosub, enableDefaultButtons
return

UpDownCloseInterv:
upDownChangeBy("CloseInterv", 5)
return

LaunchIDTool:
gosub, showIDTool
return

OpenSettingsFolder:
Run, explore %sfsoSettingsFolder%
return

OptionsGuiClose:
Gui, 1:-Disabled
Gui, options:Submit
Gui, options:Destroy
return