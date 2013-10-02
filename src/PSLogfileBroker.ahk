
; Attempts to find the correct path for pokerstars.log.0 utilizing the
; 'Open My Settings Folder' entry in PokerStars clients 'Help' menu.
; If that fails it will present a dialog for manual selection
; TODO auto detection failing is most likely due to SFSO needing elevation
; TODO rewrite this to trigger at every program start
; Alternative: use handle.exe (http://technet.microsoft.com/en-us/sysinternals/bb896655.aspx)
;	requires manual download and admin rights
;	but gets the actual file handle used by PS client
setPSLogFilePath:
IfNotExist, %psSettingsFolder%
{
	ifWinNotExist, %PS_Lobby% ahk_class %PS_CLASS%
		MsgBox, Please ensure PokerStars is running before proceeding.
	WinWait, %PS_LOBBY% ahk_class %PS_CLASS%
	; auto detection will fail if there is already a Explorer window whose address points to a folder named 'pokerstars'
	; as a workaround we first give focus to PS lobby
	; then we select "Help > Open My Settings Folder" in Lobby menu
	; this opens and activates the Explorer window we are looking for
	WinActivate, %PS_LOBBY% ahk_class %PS_CLASS%
	WinMenuSelectItem, %PS_LOBBY% ahk_class %PS_CLASS%,, Help, Open My Settings Folder
	WinWaitActive, PokerStars ahk_class CabinetWClass,, 2	; wait up to 2 seconds for the Explorer window to open
	if not ErrorLevel
	{
		WinGetText, visibleText
		WinClose
		StringGetPos, pos, visibleText, :%A_Space%	; account for 'Address' being a localized String in Windows
		pos += 2
		StringTrimLeft, visibleText, visibleText, pos		; removes 'Address: ' at the beginning
		StringGetPos, pathEndPos, visibleText, `r
		StringLeft, psSettingsFolder, visibleText, pathEndPos	; removes everything from the first `r`n onwards
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
logfilePathCurrent := psSettingsFolder . "\pokerstars.log.0"
logfilePathBackup := psSettingsFolder . "\pokerstars.log.1"

IfNotExist %logfilePathCurrent%
{
	MsgBox, Could not find "%logfilePathCurrent%", please recheck the configuration.
	ExitApp
}
return

; call with getEverything == true to retrieve the full content of PS logfiles (active and last days backup)
; if getEverything == false returns only lines added to the current logfile since the last call to getLoglines
; returns an empty string if logfile doesn't exist or doesn't contain any new lines
; getEverything corresponds to updateTourneyCount()'s fullCount parameter
getLoglines(getEverything = false)
{
	Critical
	global logfilePathCurrent, logfilePathBackup
	static filePointer := 0
	
	loglinesCapacity := 0
	loglines := ""
    oldLines := ""
	tmpLines := ""
    newLines := ""
    
	if getEverything ; get full content of both files
	{
		filePointer := 0 ; reset the file pointer to ensure we read everything from logfileCurrent afterwards
		logfileBackup := FileOpen(logfilePathBackup, "r")
		if IsObject(logfileBackup) ; fails for example on fresh installs of PS
		{
			loglinesCapacity += logFileBackup.length
			getFileContent(logFileBackup, oldLines)
			logfileBackup.Close()
		}
	}
	
	logfileCurrent := FileOpen(logfilePathCurrent, "r")
	if IsObject(logfileCurrent)
	{
		; if PS has moved to a new logfile our former logfileCurrent will now be logfileBackup
		; and logfileCurrent will point to a 'fresh' logfile
		; if this happens we check first if logfileBackup has any remaining lines left to read
		if (filePointer > logFileCurrent.length) ; triggers when PS client moves to a new logfile
		{
			logfileBackup := FileOpen(logfilePathBackup, "r")
			if (IsObject(logfileBackup) and (logfileBackup.length > filePointer))
			{
               getFileContent(logFileBackup, tmpLines, filePointer)
               logfileBackup.Close()
			}
			filePointer := 0 ; reset filePointer so we get everything from the new logfile
		}
		loglinesCapacity += logFileCurrent.length
		getFileContent(logFileCurrent, newLines, filePointer)
		filePointer := logfileCurrent.Position
		logfileCurrent.Close()
	}
   VarSetCapacity(loglines, loglinesCapacity)
   loglines := oldlines . tmpLines . newLines
   return loglines
}

; retrieves a files content from offset to eof
; uses rawRead() to allow for nul chars in file
getFileContent(ByRef file, ByRef dest, offset = 0)
{
   if IsObject(file)
   {
      file.seek(offset)
      VarSetCapacity(dest, file.length - offset)
      file.rawRead(dest, file.length)
      VarSetCapacity(dest, -1) ; rawRead doesn't update varLength
      sanitizeStr(dest)
   }
}

; based on replaceByte()
; see: http://www.autohotkey.com/board/topic/23627-machine-code-binary-buffer-searching-regardless-of-null/page-4
; not compatible with AHK_L Unicode builds but ~100 times faster than any equivalent written in AHK
; during tests AHK versions of replaceByte took about 1.3 secs for a ~2MB file which is waaaay to slow for production use
; might work on Unicode with calling RtlAnsiStringToUnicodeString
; fun contains ASM code after first call:
/*
proc ReplaceByte stdcall uses ebx ecx edx esi edi, hayStack, hayStackSize, ByteFrom:WORD, ByteTo:WORD, StartOffset, NumReps
	pushfd

	mov	ecx,[hayStackSize]
	mov	eax,[StartOffset]
	xor	edx,edx
	sub	ecx,eax
	jle	.done
	cmp	[NumReps],0
	jz	.done

	mov	edi,[hayStack]
	add	edi,eax ;edi=&(hayStack[StartOffset])

	movzx	eax,byte [ByteFrom]
	movzx	ebx,byte [ByteTo]
	cld

.rep:
	repne	scasb
	jne	.done

	mov	[edi-1],bl
	inc	edx
	dec	[NumReps]
	jz	.done
	or	ecx,ecx
	jnz	.rep

.done:
	popfd
	mov	eax,edx
	ret
endp
*/

; replaces null (0x00) bytes which cause AHK's String functions to end prematurely by first replacing them with chr(1) (0x01)
;	and removing those via StringReplace afterwards
sanitizeStr(ByRef string)
{
   static filler := chr(1)
   static inlineASM := setStaticInlineASM(inlineASM)
   IfEqual, inlineASM, 
   {
           h =
       ( LTrim join
           5589E553515256579C8B4D0C8B451831D229C17E25837D1C00741F8B7D0801C70FB6451
           00FB65D14FCF2AE750D885FFF42FF4D1C740409C975EF9D89D05F5E5A595BC9C21800
       )
       VarSetCapacity(inlineASM,StrLen(h)//2)
       Loop % StrLen(h)//2
       NumPut("0x" . SubStr(h,2*A_Index-1,2), inlineASM, A_Index-1, "Char")
   }
   if (DllCall(&inlineASM, "uint",&string, "uint",VarSetCapacity(string), "short",0, "short",1, "uint",0, "int",-1))
   {
      VarSetCapacity(string, -1) ; necessary for StringReplace to work
      StringReplace, string, string, %filler%, , A
   }
}

setStaticInlineASM(ByRef inlineASM)
{
	if inlineASM
      return
	h =
	( LTrim join
		5589E553515256579C8B4D0C8B451831D229C17E25837D1C00741F8B7D0801C70FB6451
		00FB65D14FCF2AE750D885FFF42FF4D1C740409C975EF9D89D05F5E5A595BC9C21800
	)
	VarSetCapacity(inlineASM,StrLen(h)//2)
	Loop % StrLen(h)//2
	NumPut("0x" . SubStr(h,2*A_Index-1,2), inlineASM, A_Index-1, "Char")
}
