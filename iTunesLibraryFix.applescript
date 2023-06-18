set libraryPath to "/Volumes/Macintosh HD/Users/yourUsernameHere/Music/Music/Media.localized"
set logPath to "/Users/yourUsernameHere/Desktop/iTunesFixLog.txt"

on replaceSpecialChars(myVariable)
	-- Characters to be replaced: :, /, ", and ?
	-- Curly quote h also needs to be replaced, but causes trouble with sed/perl since it's not an ASCII character.
	-- Avoiding it for now, to be fixed manually
	set searchString to "[:/€"€€?]"
	set replaceString to "_"
	
	-- Execute perl command using do shell script
	return do shell script "echo " & quoted form of myVariable & " | perl -C -pe 's#" & searchString & "#" & replaceString & "#g'"
end replaceSpecialChars

set dryRun to true

tell application "Music"
	set errorPlaylist to playlist "Error"
	set extensionList to {"mp3", "m4a", "mp4", "m4p"}
	
	repeat with trackItem in errorPlaylist's tracks
		-- get the original file path
		set originalFile to get location of trackItem
		set trackName to get name of trackItem
		
		if originalFile as text is "missing value" then
			-- get the song's metadata
			set discNumber to get disc number of trackItem
			set trackNumber to get track number of trackItem
			set trackName to get name of trackItem
			set isCompilation to get compilation of trackItem
			set artistName to get artist of trackItem
			set albumArtistName to get album artist of trackItem
			set albumName to get album of trackItem
			
			if albumArtistName is not "" then
				set artistName to albumArtistName
			end if
			
			-- Exception handling
			if isCompilation is true then
				set artistName to "Compilations"
			end if
			
			if discNumber is 0 then
				set discNumber to 1
			end if
			
			if albumName is "" then
				set albumName to "Unknown Album"
			end if
			
			if artistName is "" then
				set artistName to "Unknown Artist"
			end if
			
			-- Sanitize name strings
			set artistName to my replaceSpecialChars(artistName)
			set albumName to my replaceSpecialChars(albumName)
			set trackName to my replaceSpecialChars(trackName)
			
			-- Ensure track number is two digits
			-- Not considering albums with over 100 tracks
			if length of (trackNumber as text) is less than 2 then
				set trackNumber to "0" & trackNumber
			end if
			
			set folderPath to (libraryPath & "/" & artistName & "/" & albumName) as text
			
			-- create a new file path with the format "[disc number]-[track number] [track name].[extension]"
			
			set fileExists to false
			
			-- We don't know the correct file extension; fortunately there aren't that many so we guess
			repeat with extension in extensionList
				set newFilePathStr to (folderPath & "/" & discNumber & "-" & trackNumber & " " & trackName & "." & extension) as string
				set fileExistsCmd to (do shell script "test -e " & quoted form of newFilePathStr & " && echo 'exists' || echo 'not found'") as string
				set fileExists to (fileExistsCmd is "exists")
				
				if fileExists is true then
					exit repeat
				end if
				
			end repeat
			
			set newPath to newFilePathStr as text
			set logLine to (newPath & " " & fileExists) as text
			
			if fileExists is true then
				if dryRun is false then
					-- Apply the discovered correct path to the track in the iTunes database!
					set pathAlias to POSIX file newPath as alias
					--display dialog pathAlias as text
					set location of trackItem to pathAlias
				end if
			else
				--display dialog newFilePathStr & " not found"
			end if
			
			-- log the results
			do shell script "echo " & quoted form of logLine & " >> " & quoted form of logPath
			
		end if
	end repeat
end tell
