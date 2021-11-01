#!/bin/bash
# cleans srt formatted subtitles of common blocks that may be considered unwanted
# please consider leaving or modifying this regex to properly credit the hard work that is put into providing these subtitles

### usage:
## Download this file from the command line to your current directory:
# curl https://raw.githubusercontent.com/brianspilner01/media-server-scripts/master/sub-clean-interactive.sh > sub-clean.sh && chmod +x sub-clean.sh
## Test out what lines this script would remove:
# REGEX_TO_REMOVE='opensubtitles|sub(scene|text|rip)|podnapisi|addic7ed|yify|napisy|bozxphd|sazu489|anoxmous|(br|dvd|web).?(rip|scr)|english (- )?us|sdh|srt|(sub(title)?(bed)?(s)?(fix)?|encode(d)?|correct(ed|ion(s)?)|caption(s|ed)|sync(ed|hroniz(ation|ed))?|english)(.pr(esented|oduced))?.?(by|&)|[^a-z]www\.|http|\.( )?(com|co|link|org|net|mp4|mkv|avi)([^a-z]|$)|©|™'
# awk 'tolower($0) ~ '"/$REGEX_TO_REMOVE/" RS='' ORS='\n\n' "/path/to/sub.srt"

SUB_FILEPATH="$1"

# check usage
[ ! -f "$SUB_FILEPATH" ] && { echo "usage: sub-clean.sh [FILE]" ; echo "Warning: subtitle file does not exist" ; exit 1 ; }

# lowercase list of regex (gore/magic?) that will be removed from srt
REGEX_TO_REMOVE='opensubtitles|sub(scene|rip)|podnapisi|addic7ed|titlovi|bozxphd|sazu489|psagmeno|normita|anoxmous|(br|dvd|web).?(rip|scr)|english (- )?us|sdh|srt(?!a|o)|(yahoo|mail|book|fb|4m|hd)\. ?com|(sub(title)?(bed)?(s)?(fix)?|encode(d)?|correct(ed|ion(s)?)|caption(s|ed)|sync(ed|hroniz(ation|ed))?|english)(.pr(esented|oduced))?.?(by|&)|[^a-z]www\.|http|\. ?(co|pl|link|org|net|mp4|mkv|avi|pdf)([^a-z]|$)|©|™'

if [ "$(echo "$SUB_FILEPATH" | grep '\.srt$')" ] # only operate on srt files
then

        # convert any DOS formatted files to UNIX (remove carriage return line endings)
        awk '{ sub("\r$", ""); print }' "$SUB_FILEPATH" > "${SUB_FILEPATH}.bak" && mv "${SUB_FILEPATH}.bak" "$SUB_FILEPATH"

        ### each record (in awk) is defined as a block of srt formatted subs (record seperator RS is essentially \n\n+, see docs), with each line of the block a seperate field .i.e.:
        # LINE NUMBER
        # TIMESTAMP --> TIMESTAMP
        # SUB LINE 1
        # SUB LINE 2
        # ...
        #
		
		LINES_TO_REMOVE=$(awk 'tolower($0) ~ '"/$REGEX_TO_REMOVE/" RS='' ORS='\n\n' "$SUB_FILEPATH")
		
		if [ "$LINES_TO_REMOVE" ]
		then
			
			echo "The following lines have been marked for removal:"
			echo
			echo "#################################################"
			echo
			echo "$LINES_TO_REMOVE"
			echo
			echo "File Path:"
			echo "$SUB_FILEPATH"
			echo
			echo "#################################################"
			echo
			echo "Press enter if this is ok"
			echo "Type 'exit' to abort"
			echo "Or, type a comma seperated list of srt line numbers that should be kept (false matches)"
			read -p "$ " USER_INPUT
			
			[ "$USER_INPUT" == "exit" ] && exit
			[ "$USER_INPUT" ] || USER_INPUT="ignore"
			
			USER_INPUT=$(echo "$USER_INPUT" | sed -E 's/([0-9]+)[^0-9]/\1|/g' | sed -E 's/[0-9]+/\^&\$/g')
			
			awk 'tolower($0) !~ /'"$REGEX_TO_REMOVE"'/ || $1 ~ /'"$USER_INPUT"'/ { $1 = VAR++ ; print }' RS='' FS='\n' OFS='\n' ORS='\n\n' VAR=1 "$SUB_FILEPATH" > "$SUB_FILEPATH.tmp" && \
			mv "$SUB_FILEPATH.tmp" "$SUB_FILEPATH" && \
			chmod 666 "$SUB_FILEPATH" && \
			echo "sub-clean.sh succesfully processed $SUB_FILEPATH"
			
		else
			
			echo "Sub looks clean!"
			exit
			
		fi

else
        echo "Provided file must be .srt"
        exit 1
fi

