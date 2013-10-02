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

; option: disable lobby filter buttons while running -> no accidental changes
; add exclusion keywords for register, buyin, lobbys and reg in tourn. dialogs
; gui window to edit/add/remove filters
; TODO retrieve hwnd of filter window and operate on that - regex is slowing down get and set filter

/*
Terminology:

activeFilter:		the current state of all controls in PS clients filter window
filterName:			a filters user given name as it appears in the dropDownList in GUI_Main
					the filename under which a filter is saved is based on this (see getFileName())
selectedFilter:		global var containing the filterName currently selected in the dropDownList in GUI_Main
availableFilters:	global array containing the filterNames of all filters saved on disk

*/

; called at program start from buildGui after the GUI is shown
; once the PS Lobby is available it:
;	- sets the filter in PS client
;	- enables the filter controls in SFSO
;	- (optional) disables filter buttons in PS client
setupFilterManager:
WinWait, %PS_LOBBY% ahk_class %PS_CLASS%
fileName := getFileName(selectedFilter)
IfExist, %sfsoSettingsFolder%\Filters\%fileName%.ini
{
	setActiveFilter(loadFilter(fileName))
	; TODO disable PS filter buttons
}
else
	gosub, ButtonAddFilter ; in GUI_main.ahk, enables load/save Default buttons
gosub, enableFilterControls	; in GUI_Main.ahk
return

showAddFilterGUI()
{
	global GuiScreenPosX, GuiScreenPosY, sfsoSettingsFolder, selectedFilter
	ret := false
	openPSFilterWindow()
	Gui +OwnDialogs 
	if (selectedFilter == "")
		selectedFilter := "New Filter"
	prompt := "Set up the SNG Filter to your liking, enter a name and press OK to save"
	InputBox, newFilterName, Add new Filter, %prompt%, , 220, 170, %GuiScreenPosX%, %GuiScreenPosY%, , , %selectedFilter%
	if (ErrorLevel == 0 and newFilterName != "")
	{
		fileName := getFileName(newFilterName)
		IfExist, %sfsoSettingsFolder%\Filters\%fileName%.ini
		{
			MsgBox, 1, Filter already exists, OK to overwrite?
			IfMsgBox, OK
				FileDelete, %sfsoSettingsFolder%\Filters\%fileName%.ini
			else
			{
				closePSFilterWindow()
				return ret
			}
		}
		newFilter := getActiveFilter()
		saveFilter(newFilter, newFilterName)
		GuiControl, , selectedFilter, %newFilterName%||
		selectedFilter := newFilterName
		ret := true
	}
	closePSFilterWindow()
	return ret
}

disableFilterButtons:
Control, Disable, , %psShowFilterButton%, %PS_LOBBY% ahk_class %PS_CLASS%
Control, Disable, , %psEnableFilterButton%, %PS_LOBBY% ahk_class %PS_CLASS%
return

enableFilterButtons:
Control, Enable, , %psShowFilterButton%, %PS_LOBBY% ahk_class %PS_CLASS%
Control, Enable, , %psEnableFilterButton%, %PS_LOBBY% ahk_class %PS_CLASS%
return

; returns an array containing all available filters names
getFilterList()
{
	global sfsoSettingsFolder
	filterList := {}
	IfExist, %sfsoSettingsFolder%\Filters\*.ini
	{
		loop, %sfsoSettingsFolder%\Filters\*.ini
		{
			IniRead, name, %A_LoopFileLongPath%, Properties, name
			filterList.Insert(name)
		}
	}
	return filterList
}

; saves a filter under the given name
; the actual filename will omit any illegal characters
; the filters name as displayed in the GUI is saved in the ini
saveFilter(filter, name)
{
	global sfsoSettingsFolder
	IfNotExist, %sfsoSettingsFolder%\Filters\			; ensure Filters folder exists, otherwise saving filters won't work
		FileCreateDir, %sfsoSettingsFolder%\Filters
	fileName := getFileName(name)
	IniWrite, %name%, %sfsoSettingsFolder%\Filters\%fileName%.ini, Properties, name
	For controlName, state in filter
		IniWrite, %state%, %sfsoSettingsFolder%\Filters\%fileName%.ini, FilterStates, %controlName%
}

; loads and returns the filter given by name
loadFilter(name)
{
	global sfsoSettingsFolder
	filterControl := {}
	fileName := getFileName(name)
	IniRead, filterString, %sfsoSettingsFolder%\Filters\%fileName%.ini, FilterStates
	filter := {}
	Loop, Parse, filterString, `n
	{
		StringSplit, filterControl, A_LoopField, =
		filter.Insert(filterControl1, filterControl2)
	}
	return filter
}

; returns name cleansed of all characters that are not allowed in a filename
getFileName(name)
{
	StringReplace, name, name, %A_Space%, _, All	; replace spaces with underscores
	fileName := RegExReplace(name, "\W+")	; remove everything that isn't alphanumeric or underscore
	return fileName
}

; retrieves the currently active Filter as difference to the reset state
getActiveFilter()
{
	activeFilter := {}
	filterStates := getFilterControlStates()
	resetFilter()
	defaultFilter := getFilterControlStates()
	For controlName, state in filterStates
	{
		if (state != defaultFilter[controlName])
			activeFilter.Insert(controlName, state)
	}
	setActiveFilter(activeFilter)
	return activeFilter
}

; sets the active Filter
; resets scrlDwn and learning (the active filter directly determines how many games are available scrlDwn value is tied to the active filter
; overrides TitleMatchMode while setting filter states to improve speed
setActiveFilter(filter)
{
	global PS_FILTER_WINDOW, PS_CLASS, learning, scrlDwn
	
	learning := true
	scrlDwn := 1
	filterID := openPSFilterWindow()
	resetFilter()
	overrideTitleMatchMode(true)
	For controlName, state in filter
	{
		if (InStr(controlName, "Button"))
		{
			state := (state == 1 ? "Check" : "Uncheck")
			Control, %state%, , %controlName%, ahk_id %filterID%
		}
	}
	For controlName, state in filter
	{
		if (InStr(controlName, "Edit"))
		{
			ControlFocus, %controlName%, ahk_id %filterID%
			ControlSend, %controlName%, {Control Down}a{Control Up}{Del}%state%, ahk_id %filterID%
		}
		if (InStr(controlName, "FilterClass"))
			ControlSetText, %controlName%, %state%, ahk_id %filterID%
	}
	overrideTitleMatchMode()
	closePSFilterWindow()
}

; enumerates all controls in PS filter window
; retrieves their state (for checkboxes) or content (for edit fields)
; returns a associative array mapping control names to state/content
getFilterControlStates()
{
	global PS_FILTER_WINDOW, PS_CLASS
	controlStates := {}
	filterID := openPSFilterWindow()
	WinWait, %PS_FILTER_WINDOW% ahk_class %PS_CLASS%, , 3
	if not ErrorLevel
	{
		overrideTitleMatchMode(true)
		WinGet, ActiveControlList, ControlList, ahk_id %filterID%
		Loop, Parse, ActiveControlList, `n
		{
			if (InStr(A_LoopField, "PokerStarsButton") or InStr(A_LoopField, "ComboBox")) ; skip general buttons (reset, help etc.) and spinners
				continue
			if (InStr(A_LoopField, "Button"))
				ControlGet, state, Checked, , %A_LoopField%, ahk_id %filterID%
			if (InStr(A_LoopField, "Edit") or InStr(A_LoopField, "FilterClass"))
				ControlGetText, state, %A_LoopField%, ahk_id %filterID%
			controlStates.Insert(A_LoopField, state)
		}
		overrideTitleMatchMode()
	}
	return controlStates
}

resetFilter()
{
	global PS_FILTER_WINDOW, PS_CLASS, psResetFilterButton
	openPSFilterWindow()
	WinWait, %PS_FILTER_WINDOW% ahk_class %PS_CLASS%, , 3
	if not ErrorLevel
	{
		Sleep, 500
		ControlSend, %psResetFilterButton%, {Space}, %PS_FILTER_WINDOW% ahk_class %PS_CLASS%
	}
}

; The PS Filter window has an empty title and contains only localized text
; to make this more robust we use a regex matching an empty title: ^$
; Most (hopefully all) other windows have a title and are thus weeded out
; if this doesn't work the worst that can happen is that the filter is not open/closed
; returns the ahk_id (HWND) of the filter window
openPSFilterWindow()
{
	global PS_LOBBY, PS_FILTER_WINDOW, PS_CLASS, psShowFilterButton
	static filterID := 0
	IfWinNotExist, %PS_FILTER_WINDOW% ahk_class %PS_CLASS%
	{
		ControlSend, %psShowFilterButton%, {Space}, %PS_LOBBY% ahk_class %PS_CLASS%
		Sleep, 300
		WinGet, filterID, id, %PS_FILTER_WINDOW% ahk_class %PS_CLASS%
	}
	return filterID
}

closePSFilterWindow()
{
	global PS_FILTER_WINDOW, PS_CLASS, psCloseFilterButton
	IfWinExist, %PS_FILTER_WINDOW% ahk_class %PS_CLASS%
		ControlSend, %psCloseFilterButton%, {Space}, %PS_FILTER_WINDOW% ahk_class %PS_CLASS%
	return
}

; overrides current TitleMatchMode with mode 3
; reverts to old TitleMatchMode when enableOverride == false
overrideTitleMatchMode(enableOverride = false)
{
	static oldMode := 0
	if enableOverride
	{
		oldMode := A_TitleMatchMode
		SetTitleMatchMode, 3
	}
	else
		if oldMode
		{
			SetTitleMatchMode, %oldMode%
			oldMode := 0
		}
}
