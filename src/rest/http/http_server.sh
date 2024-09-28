#!/bin/bash

import controller/controller.sh
import controller/response.sh

import storage/manage.sh

import templates/config.sh

import util/json.sh
import util/net.sh

declare -gx HTTP_SERVER_PORT
declare -gx IS_DEBUG
declare -gx HTTP_APP_NAME

_storage_files_handler () {
    local -n uri_path_variables=$1
    local filename=${uri_path_variables[0]}

    init_response

    check_storage_file_exists "$filename"
    if [[ "$?" -eq "1" ]]; then
        local res=(
            [error]="File does not exist."
        ) 
        submit_response 404 "$(convert_object_to_json res)"
        return
    fi
    local file_ext="$(get_storage_file_extension "$filename")"
    local file_size="$(get_storage_file_size "$filename")"

    add_response_header "Content-Size" $file_size

    submit_response 200 "$(get_storage_file_absolute_path "$filename")" "$file_ext" 1
}

_static_dir_files_handler () {
    local -n uri_path_variables=$1
    local filename=${uri_path_variables[0]}

    init_response

    check_static_file_exists "$filename"
    if [[ "$?" -eq "1" ]]; then
        local res=(
            [error]="File does not exist."
        ) 
        submit_response 404 "$(convert_object_to_json res)"
        return
    fi
    local file_ext="$(get_static_dir_file_extension "$filename")"
    local file_size="$(get_static_dir_file_size "$filename")"

    add_response_header "Content-Size" $file_size

    submit_response 200 "$(get_static_dir_file_absolute_path "$filename")" "$file_ext" 1
}

_register_storage_dirs_to_serve () {
    register_endpoint_handler _storage_files_handler "GET" "/storage/{filename}" "json"
    register_endpoint_handler _static_dir_files_handler "GET" "/static/{filename}" "json"
}

_init_child_env_imports_script () {
    init_child_env_imports_file
    
    _generate_controller_imports_for_child_env "$CHILD_ENV_IMPORTS_FILE_PATH"
    _generate_response_imports_for_child_env "$CHILD_ENV_IMPORTS_FILE_PATH"
    _generate_import_manager_imports_for_child_env "$CHILD_ENV_IMPORTS_FILE_PATH"
}

start_http_server () {
    local port=$1
    local is_prod=${2:-1}
    local app_name=${3:-'App'}
    
    local script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
    local http_orchestrator="$script_dir/http_orchestrator.sh"

    HTTP_SERVER_PORT=$port
    [[ "$is_prod" -eq "0" ]] && IS_DEBUG=1
    [[ "$is_prod" -eq "1" ]] && IS_DEBUG=0
    HTTP_APP_NAME=$app_name

    local current_addr="$(get_current_ip_address)"
    set_context_domain $current_addr
    
    _register_storage_dirs_to_serve

    _init_child_env_imports_script

    ncat -l $port --keep-open --exec "$http_orchestrator"
}

export -f _storage_files_handler
export -f _static_dir_files_handler
export -f _register_storage_dirs_to_serve
export -f _init_child_env_imports_script
export -f start_http_server