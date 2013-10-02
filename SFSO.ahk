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

;written for AHK build 1.0.45.4
; ensures SFSO is run with AHK_L (ANSI 32-bit) build 1.1.13.00 or higher

if A_AhkVersion < 1.1.13.00
	MsgBox, 4112, SFSO, SFSO requires  AutoHokey_L  (ANSI 32-bit)  v1.1.13.00  or higher.
else
	if A_IsUnicode
		MsgBox, 4112, SFSO, SFSO requires the ANSI (32-bit) installation of AutoHotkey_L.`nPlease rerun the AutoHotkey setup. SFSO will now exit.
	else
		Run, main.ahk, %A_ScriptDir%\src
ExitApp