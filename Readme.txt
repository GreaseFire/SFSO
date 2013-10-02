*** Stars Filtered SNG Opener (SFSO)***

Version:	4.2

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
Once you have a filter in place head on over to the 'Advanced Settings' tab to
adjust SFSO to your play style.

Disable if no user Input (min):	Highly recommended. Set this as low as possible
								so SFSO will stop whenever you are away.
	
Number of available games:		This should be equal to the amount of games you
								see in the lobby. If in doubt choose a higher
								value.
	
Close lobbies every (sec):		For best results uncheck this and 'Auto-open
								tournament lobby' in PS 'Advanced Multi-Table
								Options'
	
Register with high frequency
	when no tables open:		Recommended. Speeds up autoregistration
								whenever there are no tables open.
	
Register in sets:				If turned on SFSO will wait until all your
								current games have finished before registering
								for more.
	
Move lobby off screen:			Use this if you are low on screen space. SFSO
								will move the Lobby back into place whenever
								autoregistering is paused, turned off or the
								'Lobby restore' button is pressed. In case SFSO
								fails to restore the Lobby you can press
								Win+Shift+Home to move it to the top left
								corner of your screen.
	
Activate open table
	after registering:			Recommended. Registering for a game will always
								activate the lobby window. With this setting
								SFSO will switch focus back to your game.
	
Register next if full:			Recommended off. PS allows skipping the buyin
								dialog via 'Advanced Multi-Table Options' which
								speeds up registration. Future versions of SFSO
								might remove this option altogether.
	
Always start at top of lobby:	Useful if your lobby is sorting games by how
								'interesting' they are, e.g. when sorting by
								the number of people enrolled.

Request Admin Privileges:		If you run PS as Administrator SFSO will also
								need administrative rights otherwise Windows
								will prevent it from accessing the lobby.

Identify PS controls:			Try this first if SFSO stops working after
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
	
