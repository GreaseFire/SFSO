
#c::gosub,NukeLobbies

#H::WinHide, ahk_id %mainGuiId%

#S::WinShow, ahk_id %mainGuiId%

/* Is this an artefact from an earlier version or does CountTourneys() have a side effect used with this Hotkey?
#F11::
TmpSetReg:=SetReg
SetReg=0
CountTourneys()
SetReg:=TmpSetReg
Return
*/

#Home::WinMove, %PS_LOBBY% ahk_class %PS_CLASS%, , 0, 0
 
~^!Q::ExitApp

#if debug
#r::Reload

Pause::
ListVars
pause
return
#if
