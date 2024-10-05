#!/bin/bash

import controller/response.sh

import storage/manage.sh

import util/log.sh
import util/time.sh

declare -gAx REQUEST_HEADERS
declare -gAx REQUEST_URI_PARAMETERS
declare REQUEST_METHOD
declare REQUEST_URI
declare REQUEST_HTTP_VERSION
declare REQUEST_BODY

declare CONTENT_LENGTH_HEADER_KEY="Content-Length"
declare CONTENT_TYPE_HEADER_KEY="Content-Type"

source "$REST_PACKAGE_BASE_DIR/meta/child_env_imports.tmp"

send() {
    printf '%s\r\n' "$*"; 
}

parse_uri_params () {
    local params="${REQUEST_URI#*\?}"
    REQUEST_URI="${REQUEST_URI%%\?*}"
    [[ "${REQUEST_URI:0:1}" != "/" ]] && REQUEST_URI="/$REQUEST_URI"
    [[ "${REQUEST_URI: -1}" != "/" ]] && REQUEST_URI="$REQUEST_URI/"

    IFS='&' read -r -a param_array <<< "$params"
    for param in "${param_array[@]}"; do
        key="${param%%=*}"
        value="${param#*=}"
        REQUEST_URI_PARAMETERS[$key]=$value
    done
}

read_request_signature () {
    read -r line
    line=${line%%$'\r'}

    read -r REQUEST_METHOD REQUEST_URI REQUEST_HTTP_VERSION <<<"$line"
    parse_uri_params
}

create_request_header_map_entry () {
    local input=$1
    input=$(echo "$input" | xargs)
    IFS=':'
    
    local key=''
    local value=''

    read -r key value <<< "$input"

    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)

    if [[ -z "$key" ]] || [[ -z "$value" ]]; then
        return 1
    fi

    REQUEST_HEADERS[$key]=$value
}

read_headers () {
    local line
    while read -r line; do
        line=${line%%$'\r'}
        [ -z "$line" ] && break
        create_request_header_map_entry "$line"
    done
}

read_body () {
    local content_length=0
    local boundary=""

    if [[ -v REQUEST_HEADERS[$CONTENT_LENGTH_HEADER_KEY] ]]; then
        content_length=${REQUEST_HEADERS[$CONTENT_LENGTH_HEADER_KEY]}
    fi

    if [[ -v REQUEST_HEADERS[$CONTENT_TYPE_HEADER_KEY] ]]; then
        local content_type=${REQUEST_HEADERS[$CONTENT_TYPE_HEADER_KEY]}
        if [[ "$content_type" == *"multipart/form-data"* ]]; then
            boundary=$(echo "$content_type" | grep -oP 'boundary=\K.+')
        fi
    fi

    if [[ "$content_length" -eq "$content_length" ]] && [[ "$content_length" -gt "0" ]]; 
    then
        if ! [[ -z "$boundary" ]]; then
            local uploaded_filename
            store_file_from_upload $boundary uploaded_filename
            REQUEST_BODY=$uploaded_filename
        else
            REQUEST_BODY=$(head -c "$content_length")
        fi
    fi
}

read_request () {
    read_request_signature
    read_headers
    read_body
}

process_request () {
    local endpoint_key=$1
    local -n matched_pattern_ref=$2

    for path_pattern in "${!ENDPOINT_HANDLERS_ARRAY[@]}"; do
        if [[ $endpoint_key =~ ^$path_pattern$ ]]; then
            local -a uri_path_variables_arr

            for ((i=1; i<${#BASH_REMATCH[@]}; i++)); do
                uri_path_variables_arr+=("${BASH_REMATCH[$i]}")
            done

            local handler_ref=${ENDPOINT_HANDLERS_ARRAY[$path_pattern]}
            eval "$handler_ref uri_path_variables_arr REQUEST_URI_PARAMETERS '$REQUEST_BODY'"
            matched_pattern_ref="$path_pattern"
            return
        fi
    done
}

send_response() {
    local code=$1
    local is_file=$2
    
    send "HTTP/1.0 $code ${HTTP_RESPONSE[$code]}"
    for i in "${!RESPONSE_HEADERS[@]}"; do
        send "$i: ${RESPONSE_HEADERS[$i]}"
    done
    send

    local line
    if [[ "$is_file" -eq "1" ]]; then
        read -r line
        cat "$line"
    fi

    if [[ "$is_file" -eq "0" ]]; then
        while read -r line; do
            send "$line"
        done
    fi
    
    log "$REQUEST_METHOD $REQUEST_URI $REQUEST_HTTP_VERSION $code" "HTTP"
}

add_time_related_response_headers () {
    local current_time=$(get_current_time) 

    add_response_header "Date" "$current_time"
    add_response_header "Expires" "$current_time"
}

add_cors_related_response_headers () {
    add_response_header "Access-Control-Allow-Origin" "*"
}

add_options_method_headers () {
    add_response_header "Connection" "keep-alive, close"
    add_response_header "Access-Control-Allow-Origin" "*"
    add_response_header "Access-Control-Allow-Methods" "POST, GET, PUT, DELETE, OPTIONS"
    add_response_header "Access-Control-Allow-Headers" "*"
    add_response_header "Access-Control-Max-Age" "86400"
}

respond_to_client () {
    local matched_pattern=$1
    
    if [[ "$REQUEST_METHOD" == "OPTIONS" ]]; then
        init_response
        add_options_method_headers 
        submit_response 204 ${HTTP_RESPONSE[204]}
    else
        if [[ -z "$matched_pattern" ]]; then
            init_response
            submit_response 404 ${HTTP_RESPONSE[404]}
        fi
    fi

    local -a response
    get_current_response response
    local code="${response[0]}"
    local mime_type="${response[1]}"
    local is_file="${response[2]}"
    local body="${response[3]}"

    if [[ ! -z "$matched_pattern" ]] && [[ "$mime_type" == "none" ]]; then
        mime_type="${ENDPOINT_MIME_TYPES_ARRAY[$matched_pattern]}"
    fi
    
    if [[ "$mime_type" == "none" ]]; then
        mime_type="plain"
    fi

    add_response_header "$CONTENT_TYPE_HEADER_KEY" "${MIME_TYPE[$mime_type]}"
    add_time_related_response_headers
    add_cors_related_response_headers

    send_response $code $is_file <<< "$body"
}

write_response () {
    local endpoint_key="$REQUEST_METHOD:$REQUEST_URI"
    local matched_pattern=""
    process_request "$endpoint_key" matched_pattern
    respond_to_client "$matched_pattern"
}

init_response_pipe
read_request $@
write_response
delete_response_pipe
