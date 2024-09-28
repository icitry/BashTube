#!/bin/bash

source ../rest/main.sh

import http/http_server.sh

import controller/controller.sh
import controller/response.sh

import db/config.sh
import db/query.sh

import storage/manage.sh

import templates/manage.sh

import util/json.sh
import util/log.sh
import util/video.sh

search_page_handler () {
    local -n uri_params=$2

    local prev="${uri_params["prev"]}"
    ! [[ -z "prev" ]] && prev='null'

    local query="${uri_params["q"]}"
    query="$(echo "$query" | base64 --decode)"

    local -a videos_list
    get_list_of_db_entries videos_list "videos" 100 "created_at" "descending" "$prev" "title LIKE '%$query%'"

    for i in ${!videos_list[@]}; do
        local -A current_entry

        local -a value_pairs
        IFS='|' read -r -a value_pairs <<< "${videos_list[$i]}"
        
        for pair in "${value_pairs[@]}"; do
            local key
            local value
            IFS=':' read -r key value <<< "$pair"
            current_entry[$key]=$value
        done
        videos_list[$i]="$(convert_object_to_json current_entry)"
    done
    
    local video_list_json="$(convert_array_to_json videos_list)"

    local context="{
        \"search\": {
            \"query\": \"$query\"
        },
        \"current_user\": {
            \"profile_picture\": \"user_icon.jpg\"
        },
        \"videos\": $video_list_json
    }"

    init_response
    submit_response 200 "$(load_html_template main/template.html "$context")"
}

home_page_handler () {
    local -n uri_params=$2

    local prev="${uri_params["prev"]}"
    ! [[ -z "prev" ]] && prev='null'

    local -a videos_list
    get_list_of_db_entries videos_list "videos" 100 "created_at" "descending" "$prev"

    for i in ${!videos_list[@]}; do
        local -A current_entry

        local -a value_pairs
        IFS='|' read -r -a value_pairs <<< "${videos_list[$i]}"
        
        for pair in "${value_pairs[@]}"; do
            local key
            local value
            IFS=':' read -r key value <<< "$pair"
            current_entry[$key]=$value
        done
        videos_list[$i]="$(convert_object_to_json current_entry)"
    done
    
    local video_list_json="$(convert_array_to_json videos_list)"

    local context="{
        \"search\": {
            \"query\": \"\"
        },
        \"current_user\": {
            \"profile_picture\": \"user_icon.jpg\"
        },
        \"videos\": $video_list_json
    }"

    init_response
    submit_response 200 "$(load_html_template main/template.html "$context")"
}

video_page_handler () {
    local -n uri_path_variables=$1

    local video_id=${uri_path_variables[0]}
    local -A video_data
    get_db_entry_by_id "videos" $video_id video_data
    local operation_res="$?"

    init_response
    if ! [[ "$operation_res" -eq "0" ]]; then
        local -A res=(
            [error]="not found"
        )
        submit_response 404 "$(convert_object_to_json res)"
        return
    fi

    local video_data_json="$(convert_object_to_json video_data)"
    
    local context="{
        \"search\": {
            \"query\": \"\"
        },
        \"current_user\": {
            \"profile_picture\": \"user_icon.jpg\"
        },
        \"video\": $video_data_json
    }"
    init_response
    submit_response 200 "$(load_html_template video/template.html "$context")"
}

update_video_handler () {
    local -n uri_path_variables=$1
    local body="$3"

    local video_id=${uri_path_variables[0]}

    local -A update_values=(
        [views]=$(get_json_base_value "$body" "views")
    )

    update_db_entry_by_id "videos" $video_id update_values
    local operation_res=$?

    init_response
    if [[ "$operation_res" -eq "0" ]]; then
        submit_response 200 "$(convert_object_to_json update_values)"
    else
        local -A res=(
            [error]="could not update entry"
        )
        submit_response 400 "$(convert_object_to_json res)"
    fi
}

create_video_entry_handler () {
    local body="$3"

    local video_path="$(get_json_base_value "$body" "path")"
    local video_extension="$(get_storage_file_extension "$video_path")"
    local thumbnail_path="$(create_video_thumbnail "$video_path")"
    
    local -A new_video_entry=(
        [title]="$(get_json_base_value "$body" "title")"
        [description]="$(get_json_base_value "$body" "description")"
        [creator_username]="$(get_json_base_value "$body" "creator")"
        [creator_profile_picture]="user_icon.jpg"
        [path]="$video_path"
        [thumbnail_path]="$thumbnail_path"
        [views]=0
        [mime_type]="${MIME_TYPE[$video_extension]}"
    )

    local entry_id=$(add_entry_to_db "videos" new_video_entry)

    init_response
    if [[ "$entry_id" -eq "0" ]]; then
        delete_storage_file "$thumbnail_path"
        local -A res=(
            [error]="Invalid input data."
        ) 

        submit_response 400 "$(convert_object_to_json res)"
        return
    fi

    local -A res
    get_db_entry_by_id "videos" $entry_id res

    submit_response 201 "$(convert_object_to_json res)"
}

upload_video_handler () {
    local body=$3
    local -A res=(
        [path]="$body"
    )

    init_response
    submit_response 201 "$(convert_object_to_json res)"
}

setup_db () {
    local -A videos_table=(
        [id]="integer primary key"
        [title]="text not null"
        [description]="text not null"
        [creator_username]="text not null"
        [creator_profile_picture]="text not null"
        [path]="text not null"
        [thumbnail_path]="text not null"
        [views]="integer not null"
        [mime_type]="text not null"
        [created_at]="datetime default current_timestamp"
    )

    create_db_table "videos" videos_table
    local videos_table_creation_res="$?"

    if ! [[ "$videos_table_creation_res" -eq "0" ]]; then
        log "Could not init database tables." "DATABASE" "ERROR"
    fi
}

create_endpoints () {
    export -f home_page_handler
    export -f search_page_handler
    export -f video_page_handler
    export -f create_video_entry_handler
    export -f update_video_handler
    export -f upload_video_handler

    register_endpoint_handler home_page_handler "GET" "/" "html"
    register_endpoint_handler search_page_handler "GET" "/search" "html"
    register_endpoint_handler create_video_entry_handler "POST" "/videos" "json"
    register_endpoint_handler video_page_handler "GET" "/videos/{id}" "html"
    register_endpoint_handler update_video_handler "PUT" "/videos/{id}" "json"
    register_endpoint_handler upload_video_handler "POST" "/upload" "json"
}

main () {
    setup_db
    create_endpoints
    start_http_server 8080 0 "BashTube"
}

main $@
