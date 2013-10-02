
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

#+Home::WinMove, PokerStars Lobby ahk_class #32770, , 0, 0
 
~^!Q::ExitApp

#if debug
Esc::Reload

Pause::
ListVars
pause
return
#if
