#!/bin/bash

declare -gx BASE_STORAGE_PATH
declare -gx STATICALLY_SERVED_DIR_PATH

set_storage_path () {
    if ! [[ -z "$BASE_STORAGE_PATH" ]]; then
        return
    fi

    local path=${1:-''}
    BASE_STORAGE_PATH="$path"
}

init_storage () {
    if test -d "$BASE_STORAGE_PATH"; then
        return
    fi

    mkdir -p "$BASE_STORAGE_PATH"
}

set_static_dir_path () {
    if ! [[ -z "$STATICALLY_SERVED_DIR_PATH" ]]; then
        return
    fi

    local path=${1:-''}
    STATICALLY_SERVED_DIR_PATH="$path"
}

init_static_dir () {
    if test -d "$STATICALLY_SERVED_DIR_PATH"; then
        return
    fi

    mkdir -p "$STATICALLY_SERVED_DIR_PATH"
}

export -f set_storage_path
export -f init_storage
export -f set_static_dir_path
export -f init_static_dir