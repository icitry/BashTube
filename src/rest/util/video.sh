#!/bin/bash

create_video_thumbnail () {
    local video_src=$1
    video_src="$(get_storage_file_absolute_path "$video_src")"

    local thumbnail_path="upload_thumbnail_$(uuidgen).png"

    local duration=$(ffmpeg -i "$video_src" 2>&1 | grep "Duration" | awk '{print $2}' | tr -d ,)
    local total_seconds=$(echo "$duration" | awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }')
    local target_seconds=$(echo "$total_seconds * 0.5" | bc)

    ffmpeg -ss "$target_seconds" -i "$video_src" -frames:v 1 -update true "$(get_storage_file_absolute_path $thumbnail_path)" &> /dev/null

    echo "$thumbnail_path"
}

export -f create_video_thumbnail