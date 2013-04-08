(*
"FLAC to iTunes"
written by Chris Runge
chrisrunge@mac.com

This AppleScript converts and imports a folder of FLAC (http://flac.sourceforge.net/) audio files into iTunes. 

Requirements:
- /usr/local/bin/flac
- /usr/local/bin/metaflac

To get these files do the following:
(1) Download "FLAC 1.1.2 for OS X (no installer)" from http://flac.sourceforge.net/download.html 
(2) From the Terminal
    (a) Unpack the archive, e.g.,
        tar xvfz flac-1.1.2-osx-ppc.tar.gz 
    (b) Change to the folder that was unpacked, e.g.,
        cd flac-1.1.2-osx-ppc
    (c) Copy the flac and metaflac binaries to /usr/local/bin, e.g., 
        sudo cp bin/* /usr/local/bin

v0.2 Dec 26 2005
- add dialog when conversion is complete

v0.1 Dec 23 2005
- initial release
*)

set flacBinary to "/opt/local/bin/flac"
set metaflacBinary to "/opt/local/bin/metaflac"
set temporaryWav to POSIX path of (path to "temp" from user domain) & "decodedFlac.wav"

-- prompt the user for the folder of FLAC files to convert and import
set flacFiles to {}
set flacFolder to choose folder with prompt "Choose the folder of FLAC files to import into iTunes."
tell application "Finder" to set all_files to every file of entire contents of folder flacFolder whose name extension is "flac"
repeat with a_file in all_files
	set end of flacFiles to (quoted form of POSIX path of (a_file as Unicode text))
end repeat

-- prompt the user for the encoder to use when converting and importing the FLAC files
tell application "iTunes"
	activate
	
	-- plural for dialog (taken from Doug's Applescripts)
	set s to "s"
	if (count of items in flacFiles) is 1 then set s to ""
	
	set availableEncoders to name of every encoder
	
	-- store the existing preferred encoder as found in iTunes Preferences
	set preferredEncoder to name of current encoder
	
	set myNewEncoder to (choose from list availableEncoders with prompt ¬
		"Convert track" & s & " using..." default items (preferredEncoder as list) ¬
		OK button name "OK" cancel button name ¬
		"Cancel" without multiple selections allowed and empty selection allowed) as string
	if myNewEncoder is "false" then error number -128
	
	set current encoder to encoder myNewEncoder
end tell

-- process the folder of FLAC files, converting and importing each one    
repeat with i from 1 to (count flacFiles)
	
	set flacFile to (item i of the flacFiles)
	
	-- extract metadata from the flac audio file
	set trackArtist to do shell script metaflacBinary & " " & flacFile & " --show-tag=ARTIST | sed s/.*=//g"
	set trackTitle to do shell script metaflacBinary & " " & flacFile & " --show-tag=TITLE | sed s/.*=//g"
	set trackAlbum to do shell script metaflacBinary & " " & flacFile & " --show-tag=ALBUM | sed s/.*=//g"
	set trackGenre to do shell script metaflacBinary & " " & flacFile & " --show-tag=GENRE | sed s/.*=//g"
	set trackDate to do shell script metaflacBinary & " " & flacFile & " --show-tag=DATE | sed s/.*=//g"
	set trackComment to do shell script metaflacBinary & " " & flacFile & " --show-tag=COMMENT | sed s/.*=//g"
	set trackNumber to do shell script metaflacBinary & " " & flacFile & " --show-tag=TRACKNUMBER | sed s/.*=//g"
	
	-- decode the flac audio file
	do shell script flacBinary & " -d " & flacFile & " -o " & temporaryWav & " -f"
	set ptemporaryWav to POSIX file temporaryWav
	
	-- convert, import, and tag
	tell application "iTunes"
		set newTrack to item 1 of (convert ptemporaryWav)
		set artist of newTrack to trackArtist
		set name of newTrack to trackTitle
		set album of newTrack to trackAlbum
		set genre of newTrack to trackGenre
		set year of newTrack to trackDate
		set comment of newTrack to trackComment
		set track number of newTrack to trackNumber
	end tell
	
end repeat

tell application "iTunes"
	-- restore preferred encoder to iTunes Preferences
	set current encoder to encoder preferredEncoder
	display dialog "Finished!" buttons {"OK"} default button 1 with icon 1
end tell

