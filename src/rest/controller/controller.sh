#!/bin/bash

declare -gAx ENDPOINT_HANDLERS_ARRAY
declare -gAx ENDPOINT_MIME_TYPES_ARRAY

declare -gAx MIME_TYPE=(
    [plain]="text/plain"
    [octet-stream]="application/octet-stream"
    [bin]="application/octet-stream"
    [html]="text/html"
    [js]="text/javascript"
    [css]="text/css"
    [json]="application/json"
    [png]="image/png"
    [jpg]="image/jpeg"
    [jpeg]="image/jpeg"
    [gif]="image/gif"
    [svg]="image/svg+xml"
    [avif]="image/avif"
    [webp]="image/webp"
    [avi]="video/x-msvideo"
    [mp4]="video/mp4"
    [mpeg]="video/mpeg"
    [webm]="video/webm"
)

create_regex_for_path () {
    local path=$1
    local pattern=$(echo "$path" | sed -E 's@\{[a-zA-Z0-9]+\}@([^/]+)@g')
    echo "$pattern"
}

register_endpoint_handler () {
    local handler_ref=$1
    local http_method=${2:-"GET"}
    local path=${3:-"/"}
    local mime_type=${4:-"plain"}

    [[ "${path:0:1}" != "/" ]] && path="/$path"
    [[ "${path: -1}" != "/" ]] && path="$path/"

    ! [[ -v MIME_TYPE[$mime_type] ]] && mime_type="plain";

    path="$(create_regex_for_path $path)"
    local endpoint_key="$http_method:$path"

    ENDPOINT_HANDLERS_ARRAY[$endpoint_key]=$handler_ref
    ENDPOINT_MIME_TYPES_ARRAY[$endpoint_key]=$mime_type
}

_generate_controller_imports_for_child_env () {
    local env_file_path=$1
    declare -p ENDPOINT_HANDLERS_ARRAY >> "$env_file_path"
    declare -p ENDPOINT_MIME_TYPES_ARRAY >> "$env_file_path"
    declare -p MIME_TYPE >> "$env_file_path"
}

export -f create_regex_for_path
export -f register_endpoint_handler
