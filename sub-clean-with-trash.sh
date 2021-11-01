#!/bin/bash
# cleans srt formatted subtitles of common blocks that may be considered unwanted, works well as a post-process script for software such as Bazarr or Sub-Zero
# includes optional trash folder for "back up" of unmodified subtitle as well as a list of removed records (for reviewal)
# if trash directory is ommitted, sub is modified in-place
# please consider leaving or modifying this regex to properly credit the hard work that is put into providing these subtitles

SUB_FILEPATH="$1"

# check usage
[ ! -f "$SUB_FILEPATH" ] && { echo "usage: sub-clean.sh [FILE] <TRASH DIR>" ; echo "Warning: subtitle file does not exist" ; exit 1 ; }

# define trash folder (leave blank to disable trash) used for backing up unprocessed sub
TRASH="$2"

# lowercase list of regex (gore/magic?) that will be removed from srt
REGEX_TO_REMOVE='opensubtitles|sub(scene|rip)|podnapisi|addic7ed|titlovi|bozxphd|sazu489|psagmeno|normita|anoxmous|(br|dvd|web).?(rip|scr)|english (- )?us|sdh|srt(?!a|o)|(yahoo|mail|book|fb|4m|hd)\. ?com|(sub(title)?(bed)?(s)?(fix)?|encode(d)?|correct(ed|ion(s)?)|caption(s|ed)|sync(ed|hroniz(ation|ed))?|english)(.pr(esented|oduced))?.?(by|&)|[^a-z]www\.|http|\. ?(co|pl|link|org|net|mp4|mkv|avi|pdf)([^a-z]|$)|©|™'

# removed lines will be placed in this file
SUB_BIN="$TRASH/$(basename "$SUB_FILEPATH")-removed.txt"
[ -z "$TRASH" ] && SUB_BIN=/dev/null

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

        # each line not containing a matching regex (ad) is printed to an output file in the trash folder, every other line is kept with the LINE NUMBER regenerated appropriately. The original sub-file is also "backed-up" to the trash folder

        awk 'tolower($0) !~ /'"$REGEX_TO_REMOVE"'/ { $1 = VAR++ ; print ; next } { print > BIN }' RS='' FS='\n' OFS='\n' ORS='\n\n' VAR=1 BIN="$SUB_BIN" "$SUB_FILEPATH" > "$SUB_FILEPATH.tmp" && SUCCESS=1

        if [ "$SUCCESS" -eq 1 ]
        then
                if [ -z "$TRASH" ]
                then
                        mv "$SUB_FILEPATH.tmp" "$SUB_FILEPATH"
                        chmod 666 "$SUB_FILEPATH"
                else
                        if [ "$(cat -b "$SUB_FILEPATH" | wc -l)" -eq "$(cat -b "$SUB_FILEPATH.tmp" | wc -l)" ] #if no ads were found (compare number of non-empty lines)
                        then
                                rm "$SUB_FILEPATH.tmp"
                        else
                                mv -f "$SUB_FILEPATH" "$TRASH"
                                mv -f "$SUB_FILEPATH.tmp" "$SUB_FILEPATH"
                                chmod 666 "$SUB_FILEPATH"
                        fi
                fi
        else
                rm "$SUB_FILEPATH.tmp"
                echo "Failed to process subtitle"
                exit 1
        fi
else
        echo "Provided file must be .srt"
        exit 1
fi
