#!/bin/bash

import storage/config.sh
import util/math.sh

_consume_data_headers () {
    local -n filename_ref=$1

    local line
    while read -r line; do
        line=${line%%$'\r'}
        [ -z "$line" ] && break
        if ! [[ -z "$(echo "$line" | grep -aoP 'filename="\K[^"]+')" ]]; then
            filename_ref="$(echo "$line" | grep -aoP 'filename="\K[^"]+')"
        fi
    done
}

_remove_boundary_data_from_file () {
    local path=$1
    local boundary_str=$2
    local byte_offset=$(xxd -p "$path" | tr -d ' \n' | grep -b -o "$(echo -n "--$boundary_str--" | xxd -p | tr -d ' \n')" | awk -F: '{print $1/2}')

    if [[ -z "$byte_offset" ]]; then 
        return
    fi

    if ! [[ "$(is_number "$byte_offset")" -eq "1" ]]; then
        return
    fi

    byte_offset=$((byte_offset-1))

    local tmp_file="$BASE_STORAGE_PATH/tmp_$(uuidgen).bin"

    dd if="$path" of="$tmp_file" bs=1 count=$byte_offset &> /dev/null
    mv "$tmp_file" "$path" &> /dev/null
}

store_file_from_upload () {
    local boundary=$1
    local -n uploaded_filename_ref=$2

    local filename="file.bin"
    _consume_data_headers filename

    filename=$(basename -- "$filename")
    local extension="${filename##*.}"

    uploaded_filename_ref="video_upload_$(uuidgen).$extension"
    
    local output_file_path="$BASE_STORAGE_PATH/$uploaded_filename_ref"

    local chunk_size=2048
    while dd if=/dev/stdin of="$output_file_path" bs="$chunk_size" count=1 oflag=append conv=notrunc status=none; do
        local end_boundary=$(grep -aon -- "--$boundary--" "$output_file_path" | tail -n 1 | cut -d: -f1)
        if ! [[ -z "$end_boundary" ]]; then
            break
        fi
    done

    _remove_boundary_data_from_file $output_file_path $boundary
}

move_storage_file () {
    local old_path=$1
    local new_path=$2

    eval "mv $BASE_STORAGE_PATH/$old_path $BASE_STORAGE_PATH/$new_path"
}

delete_storage_file () {
    local path=$1

    eval "rm -rf $BASE_STORAGE_PATH/$path"
}

check_storage_file_exists () {
    local filename=$1

    if ! test -f "$BASE_STORAGE_PATH/$filename"; then
        return 1
    fi

    return 0
}

get_storage_file_absolute_path () {
    local filename=$1
    echo "$BASE_STORAGE_PATH/$filename"
}

get_storage_file_extension () {
    local path="$BASE_STORAGE_PATH/$1"
    local filename=$(basename -- "$path")
    local extension="${filename##*.}"

    echo "$extension"
}

get_storage_file_size () {
    local filename=$1
    local file_size=$(stat -c%s "$BASE_STORAGE_PATH/$filename")

    echo "$file_size"
}

check_static_file_exists () {
    local filename=$1

    if ! test -f "$STATICALLY_SERVED_DIR_PATH/$filename"; then
        return 1
    fi

    return 0
}

get_static_dir_file_absolute_path () {
    local filename=$1
    echo "$STATICALLY_SERVED_DIR_PATH/$filename"
}

get_static_dir_file_extension () {
    local path="$STATICALLY_SERVED_DIR_PATH/$1"
    local filename=$(basename -- "$path")
    local extension="${filename##*.}"

    echo "$extension"
}

get_static_dir_file_size () {
    local filename=$1
    local file_size=$(stat -c%s "$STATICALLY_SERVED_DIR_PATH/$filename")

    echo "$file_size"
}

export -f _consume_data_headers
export -f _remove_boundary_data_from_file
export -f store_file_from_upload
export -f move_storage_file
export -f delete_storage_file
export -f check_storage_file_exists
export -f get_storage_file_absolute_path
export -f get_storage_file_extension
export -f get_storage_file_size
export -f check_static_file_exists
export -f get_static_dir_file_absolute_path
export -f get_static_dir_file_extension
export -f get_static_dir_file_size
