#!/bin/bash
# cleans srt formatted subtitles of common blocks that may be considered unwanted, works well as a post-process script for software such as Bazarr or Sub-Zero
# please consider leaving or modifying this regex to properly credit the hard work that is put into providing these subtitles

SUB_FILEPATH="$1"

# check usage
[ ! -f "$SUB_FILEPATH" ] && { echo "usage: sub-clean.sh [FILE]" ; echo "Warning: subtitle file does not exist" ; exit 1 ; }

# convert any DOS formatted files to UNIX (remove carriage return line endings)
sed -i 's/\r$//' "$SUB_FILEPATH"

# lowercase list of regex (gore/magic?) that will be removed from srt
REGEX_TO_REMOVE='opensubtitles|sub(scene|text|rip)|podnapisi|addic7ed|yify|napisy|bozxphd|sazu489|anoxmous|(br|dvd|web).?(rip|scr)|english (- )?us|sdh|srt|(sub(title)?(bed)?(s)?(fix)?|encode(d)?|correct(ed|ion(s)?)|caption(s|ed)|sync(ed|hroniz(ation|ed))?|english)(.pr(esented|oduced))?.?(by|&)|[^a-z]www\.|http|\.( )?(com|co|link|org|net|mp4|mkv|avi)([^a-z]|$)|©|™'

if [[ $SUB_FILEPATH =~ \.srt$ ]] # only operate on srt files
then

        ### each record (in awk) is defined as a block of srt formatted subs (record seperator RS is essentially \n\n+, see docs), with each line of the block a seperate field .i.e.:
        # LINE NUMBER
        # TIMESTAMP --> TIMESTAMP
        # SUB LINE 1
        # SUB LINE 2
        # ...
        #
        
        awk 'tolower($0) !~ /'"$REGEX_TO_REMOVE"'/ { $1 = VAR++ ; print }' RS='' FS='\n' OFS='\n' ORS='\n\n' VAR=1 "$SUB_FILEPATH" > "$SUB_FILEPATH.tmp" && \
        mv "$SUB_FILEPATH.tmp" "$SUB_FILEPATH" && \
        chmod 666 "$SUB_FILEPATH"

else
        echo "Provided file must be .srt"
        exit 1
fi
