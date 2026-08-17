#!/bin/bash

folder="$1"

find "$folder" -type f -iname "*.mp3" | while read -r file
do
    title=$(ffprobe -v quiet \
        -show_entries format_tags=title \
        -of default=noprint_wrappers=1:nokey=1 \
        "$file")

    echo "$(basename "$file")"
    echo "Title: $title"
    echo "----------------------"

done
