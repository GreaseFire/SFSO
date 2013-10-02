*** Stars Filtered SNG Opener (SFSO)***

Version:	4.3

For questions and feedback visit:
http://forumserver.twoplustwo.com/168/free-software/ahk-script-stars-filtered-sng-opener-234749/

Installation:
Extract to a folder of your choice. If you don't have AutoHotkey_L installed or
use a different version you can run SFSO.exe.
SFSO.exe is the official AHK_L interpreter found as AutoHotkeyA32.exe in any
normal installation of AutoHotkey_L build 1.1.13.0.


Before you start using the program:
	FILTER YOUR POKERSTARS LOBBY FOR ONLY THOSE GAMES YOU INTEND TO PLAY
	
3rd party programs and scripts only get very limited access to the PS client.
In particular there is no way to discover which games (if any) are shown in the
lobby. As a result SFSO is essentially blind to what games it registers for.

A powerful way to narrow the filter down is to use the 'Find a tournament...' Box right
at the top. It allows you to use these symbols:
+	(optional) include in search
-	exclude from search
|	add a second filter string


Setting up SFSO:
Once you have a filter in place click on the 'Options' button to adjust SFSO to
your play style.

Disable if no user Input (min):	Highly recommended. Set this as low as possible
								so SFSO will stop whenever you are away.
	
Close lobbies every (sec):		For best results uncheck this and 'Auto-open
								tournament lobby' in PS 'Advanced Multi-Table
								Options'

Register in sets:				If turned on SFSO will wait until all your
								current games have finished before registering
								for more.
	
Register with high frequency
	at session start:			Recommended. Speeds up autoregistration at the
								beginning. SFSO will switch to using 'Register
								every(sec)' setting after a few games have
								started.
	
Activate open table
	after registering:			Recommended. Registering for a game will always
								activate the lobby window. With this setting
								SFSO will switch focus back to your game.
	
Always start at top of lobby:	If checked SFSO will always move back to the
								first game in the lobby when searching for a
								new game to register 	Useful if your lobby is
								sorting games by how 'interesting' they are,
								e.g. when sorting by the number of people
								enrolled.

Move lobby off screen:			Use this if you are low on screen space. SFSO
								will move the Lobby back into place whenever
								autoregistering is paused, turned off or the
								'Lobby restore' button is pressed. In case SFSO
								fails to restore the Lobby you can press
								Win+Shift+Home to move it to the top left
								corner of your screen.
	
Register next if full:			Recommended off. PS allows skipping the buyin
								dialog via 'Advanced Multi-Table Options' which
								speeds up registration. Future versions of SFSO
								might remove this option altogether.
Wait for rematch decision:		If checked SFSO will wait while a rematch
								dialog is displayed giving you time to accept
								or decline. Closing all rematch dialogs will
								continue auto registration.
Request Admin Privileges:		If you run PS as Administrator SFSO will also
								need administrative rights otherwise Windows
								will prevent it from accessing the lobby.

Identify PS Controls:			Try this first if SFSO stops working after
								changing your lobby theme or PS updates the
								client software.


Now that you have a filter in place and adjusted SFSO to your liking it's time
to switch back to the 'General' tab. If you are new to SFSO it's a good idea to
start with lower settings first and gradually turn them up until you have a
comfortable setup.

Register every (sec):			How long SFSO waits before registering for a
								new game. 'Register with high frequency' on
								the advanced tab affects this setting.

No of SNG:s to keep open:		How many games you want to play at the same
								time.

Limit total SNG:s to:
Limit total time to (min):		Determines when SFSO should stop. Can be used
								in conjunction. Keep in mind that the time
								limit does not account for the time it takes
								you to finish your games. 
	
Filters:						Select a saved filter from the list to put it
								into effect. To add a new filter or add/rename
								existing ones press 'Edit'.
