
; Attempts to find the correct path for pokerstars.log.0 utilizing the
; 'Open My Settings Folder' entry in PokerStars clients 'Help' menu.
; If that fails it will present a dialog for manual selection
setPSLogFilePath:
IfNotExist, %psSettingsFolder%
{
	ifWinNotExist, PokerStars Lobby ahk_class #32770
		MsgBox, Please ensure PokerStars is running before proceeding.
	WinWait, PokerStars Lobby ahk_class #32770
	; auto detection will fail if there is already a Explorer window whose address points to a folder named 'pokerstars'
	; as a workaround we first give focus to PS lobby
	; then we select "Help > Open My Settings Folder" in Lobby menu
	; this opens and activates the Explorer window we are looking for
	WinActivate, PokerStars Lobby ahk_class #32770
	WinMenuSelectItem, PokerStars Lobby ahk_class #32770,, Help, Open My Settings Folder
	WinWaitActive, PokerStars ahk_class CabinetWClass,, 2	; wait up to 2 seconds for the Explorer window to open
	if not ErrorLevel
	{
		WinGetText, visibleText
		WinClose
		StringTrimLeft, visibleText, visibleText, 9		; removes 'Address: ' at the beginning
		StringGetPos, pathEndPos, visibleText, `r
		StringLeft, psSettingsFolder, visibleText, pathEndPos	; removes everything from the first CR onwards
	}
	else
	{
		MsgBox, Auto detection of PokerStars settings folder failed.`nClick 'OK' to manually select the folder
		if A_OSVersion in WIN_2003,WIN_XP,WIN_2000
			startFolder := %A_AppData%
		else EnvGet, startFolder, LOCALAPPDATA	; for Win Vista/7/8
		FileSelectFolder, psSettingsFolder, %startFolder%, 0, Select Pokerstars settings folder
	}
	IniWrite, %psSettingsFolder%, %sfsoSettingsFolder%\SFSO.ini, Settings, psSettingsFolder
}
logfile := psSettingsFolder . "\pokerstars.log.0"
IfNotExist %logfile%
{
	MsgBox, Could not find "%logfile%", please recheck the configuration.
	ExitApp
}
return

; TODO: get rid of this coding horror (as well as checkFile)
;	at the very least this needs to be updated to work on Unicode builds, but
ReplaceByte( hayStackAddr, hayStackSize, ByteFrom=0, ByteTo=1, StartOffset=0, NumReps=-1)
{	Static fun := ""
	IfEqual,fun,
	{
		h=
		( LTrim join
			5589E553515256579C8B4D0C8B451831D229C17E25837D1C00741F8B7D0801C70FB6451
			00FB65D14FCF2AE750D885FFF42FF4D1C740409C975EF9D89D05F5E5A595BC9C21800
		)
		VarSetCapacity(fun,StrLen(h)//2)
		Loop % StrLen(h)//2
			NumPut("0x" . SubStr(h,2*A_Index-1,2), fun, A_Index-1, "Char")
	}
	Return DllCall(&fun
		, "uint",haystackAddr, "uint",hayStackSize, "short",ByteFrom, "short",ByteTo
		, "uint",StartOffset, "int",NumReps)
}

; mode == 1	returns full File content
; mode == 0	returns only what was appended to File since the last call to CheckFile
; returns false on error
; TODO: change return false to return ""
;			or store the content in a ByRef variable 
;			and return the amount read (if nothing is read this would be 0 and intuitive false
;		refactor DllCall and VarSetCapacity for Unicode compatibility
CheckFile(File, mode=0) {
   ; THX Sean for File.ahk : http://www.autohotkey.com/forum/post-124759.html
   Static CF := ""   ; Current File
   Static FP := 0    ; File Pointer
   Static OPEN_EXISTING := 3
   Static GENERIC_READ := 0x80000000
   Static FILE_SHARE_READ := 1
   Static FILE_SHARE_WRITE := 2
   Static FILE_SHARE_DELETE := 4
   Static FILE_BEGIN := 0
   nSize := 0
   BatchLines := A_BatchLines
   SetBatchLines, -1
   If (File != CF) {
      CF := File
      FP := 0
   }
   hFile := DllCall("CreateFile"
                  , "Str",  File
                  , "Uint", GENERIC_READ
                  , "Uint", FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_SHARE_DELETE
                  , "Uint", 0
                  , "Uint", OPEN_EXISTING
                  , "Uint", 0
                  , "Uint", 0)
   If (!hFile) {
      CF := ""
      FP := 0
      SetBatchLines, %BatchLines%
      Return False
   }
   DllCall("GetFileSizeEx"
         , "Uint",   hFile
         , "Int64P", nSize)
   if mode=1
	FP:=1
   If (FP = 0 Or nSize <= FP) {
      FP := nSize
      SetBatchLines, %BatchLines%
      DllCall("CloseHandle", "Uint", hFile) ; close file
     Return False
   }
   DllCall("SetFilePointerEx"
         , "Uint",  hFile
         , "Int64", FP
         , "Uint",  0
         , "Uint",  FILE_BEGIN)
   VarSetCapacity(Tail, Length := nSize - FP, 0)
   DllCall("ReadFile"
         , "Uint",  hFile
         , "Str",   Tail
         , "Uint",  Length
         , "UintP", Length
         , "Uint",  0)
   DllCall("CloseHandle", "Uint", hFile)
   ReplaceByte( &Tail, Length)
   VarSetCapacity(Tail, -1)
   FP := nSize
   SetBatchLines, %BatchLines%
   Return Tail
}
