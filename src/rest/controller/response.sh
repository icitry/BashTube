#!/bin/bash

declare -gAx HTTP_RESPONSE=(
   [200]="OK"
   [400]="Bad Request"
   [403]="Forbidden"
   [404]="Not Found"
   [405]="Method Not Allowed"
   [500]="Internal Server Error"
)

declare -gx RESPONSE_TMP_FILE

declare -gAx RESPONSE_HEADERS

init_response_pipe () {
    RESPONSE_TMP_FILE=/tmp/rest_response_tmp_file_$(uuidgen -t).XXXXXX

    rm -f $RESPONSE_TMP_FILE &&
    mktemp $RESPONSE_TMP_FILE >/dev/null 2>&1
}

delete_response_pipe () {
    rm -f $RESPONSE_TMP_FILE
}

init_response () {
    RESPONSE_HEADERS=()
}

submit_response () {
    local code="$1"
    local body="$2"
    local mime_type=${3:-"none"}
    local is_file=${4:-"0"}

    echo -e "$code\n$mime_type\n$is_file\n$body" > "$RESPONSE_TMP_FILE"
}

get_current_response () {
    local -n current_response_ref=$1

    current_response_ref[0]="$(head -n 1 $RESPONSE_TMP_FILE)"
    current_response_ref[1]="$(head -n 2 $RESPONSE_TMP_FILE | awk 'NR > 1')"
    current_response_ref[2]="$(head -n 3 $RESPONSE_TMP_FILE | awk 'NR > 2')"
    current_response_ref[3]="$(cat $RESPONSE_TMP_FILE | awk 'NR > 3')"
}

add_response_header() {
    local key="$1"
    local value="$2"
    RESPONSE_HEADERS[$key]=$value
}

_generate_response_imports_for_child_env () {
    local env_file_path=$1
    declare -p HTTP_RESPONSE >> "$env_file_path"
}

export -f init_response_pipe
export -f init_response
export -f submit_response
export -f add_response_header
