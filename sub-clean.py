#!/usr/bin/env python3

# this adaption of sub-clean.sh is credited to u/Msuix

## IMPORTANT: Install srt pypi module first https://pypi.org/project/srt/ or leave srt.py in the same folder as this script
## e.g. run `pip3 install -U srt`

# cleans srt formatted subtitles of common blocks that may be considered unwanted, works well as a post-process script for software such as Bazarr or Sub-Zero
# please consider leaving or modifying this regex to properly credit the hard work that is put into providing these subtitles

import sys, re
from pathlib import Path
try:
        import srt
except:
        print("Error: exception during import. do you have the srt python module installed or present in the same directory?")
        exit(1)

REGEX_TO_REMOVE = re.compile(r'(br|dvd|web).?(rip|scr)|english (- )?us|sdh|srt(?!a|o)|(yahoo|mail|book|fb|4m|hd)\. ?com|(sub(title)?(bed)?(s)?(fix)?|encode(d)?|correct(ed|ion(s)?)|caption(s|ed)|sync(ed|hroniz(ation|ed))?|english)(.pr(esented|oduced))?.?(by|&)|[^a-z]www\.|http|\. ?(co|pl|link|org|net|mp4|mkv|avi|pdf)([^a-z]|$)|©|™|opensubtitles|sub(scene|rip)|podnapisi|addic7ed|titlovi|bozxphd|sazu489|psagmeno|normita|anoxmous|isubdb|americascardroom')

try:
        subFileObj = Path(sys.argv[1])
except:
        print("usage: sub-clean.py [FILE]")
        exit(1)

if not subFileObj.is_file():
        print("usage: sub-clean.py [FILE]")
        print("Warning: subtitle file does not exist")
        exit(1)

if subFileObj.suffix != '.srt':
        print("Warning: provided file must be .srt")
        exit(1)

try:
        subs = None
        with open(subFileObj,'r') as fi:
                subs = list(srt.parse(fi.read()))
except:
        print("Error: Could not parse subs from {subsfile}".format(subsfile=subFileObj.absolute()))
        exit(1)

#remove ads
try:
        filtered_subs = [x for x in subs if not REGEX_TO_REMOVE.search(x.content.lower())]
except:
        print("Error: Failed processing during ad filtering step - Check your regex pattern.")
        exit(1)

with open(subFileObj,'w') as fi:
        fi.write(srt.compose(filtered_subs))
        print("Successfully Ad-Filtered '{subsfile}'".format(subsfile=subFileObj.name))
