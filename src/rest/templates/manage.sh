#!/bin/bash

import templates/config.sh
import util/json.sh

_replace_global_variables_values () {
    local -n template_content_ref=$1
    template_content_ref=$(echo "$template_content_ref" | sed "s@{DOMAIN}@${HTML_TEMPLATES_CONTEXT_DOMAIN}@g")
    template_content_ref=$(echo "$template_content_ref" | sed "s@{APPNAME}@${HTTP_APP_NAME}@g")
    template_content_ref=$(echo "$template_content_ref" | sed "s@{STATIC_DIR}@${HTML_TEMPLATES_CONTEXT_DOMAIN}/static@g")
    template_content_ref=$(echo "$template_content_ref" | sed "s@{STORAGE}@${HTML_TEMPLATES_CONTEXT_DOMAIN}/storage@g")
}

_extract_context_variable_value () {
    local context_str=$1
    local context_variable=$2
    local variable_root=${3:-"CONTEXT"}
    local key_path=$(echo "$context_variable" | sed "s/^$variable_root\.//")

    local variable_value=$(get_json_nested_base_value "$context_str" "$key_path")
    echo "$variable_value"
}

_replace_context_variables () {
    local context_obj=$1
    local -n template_content_ref=$2

    while echo "$template_content_ref" | grep -q '{CONTEXT\.[^}]\+}'; do
        local match=$(echo "$template_content_ref" | grep -o '{CONTEXT\.[^}]\+}' | head -n 1)
        local keypath=${match:1:-1}
        local value=$(_extract_context_variable_value "$context_obj" "$keypath")
        match="$(echo "$match" | sed 's/\./\\./g; s/\[/\\[/g; s/\]/\\]/g')"
        template_content_ref=$(echo "$template_content_ref" | sed "s@$match@$value@g")
    done
}

_escape_content_for_sed () {
    local content="$1"
    content="$(echo "$content" | sed -e 's/[.[\*^$(){}|?+\\]/\\&/g'  -e 's/ /\\ /g' -e 's/"/\\"/g' -e "s/'/\\'/g")"
    content="${content//$'\n'/'\\n'}"
    content="${content//$'\t'/'\\t'}"
    echo -e "$content"
}

_replace_for_loops () {
    local context_obj=$1
    local -n template_content_ref=$2

    local loop_block=$(echo "$template_content_ref" | sed -n '/{#for/,/{\/for}/p' | sed -n '1,/\/for}/p')
    while ! [[ -z "$loop_block" ]]; do
        local loop_definition=$(echo "$loop_block" | grep -oP "{#for\s+\K[^\}]+(?=\})")
        local loop_variable=$(echo "$loop_definition" | awk '{print $1}')
        local loop_data_source=$(echo "$loop_definition" | awk '{print $3}')
        local loop_contents=$(echo "$loop_block" | sed '1d;$d')

        local items_array_str=$(_extract_context_variable_value "$context_obj" "$loop_data_source")
        
        local -a items_array
        get_json_array_items "$items_array_str" items_array

        local final_output=""
        for item in "${items_array[@]}"; do
            local current_loop=$loop_contents
            while echo "$current_loop" | grep -qe "{$loop_variable\(\.[^}]\+\)\?}" ; do
                local match=$(echo "$current_loop" | grep -o "{$loop_variable\(\.[^}]\+\)\?}" | head -n 1)
                local keypath=${match:1:-1}
                local value=$(_extract_context_variable_value "$item" "$keypath" "$loop_variable")

                match="$(echo "$match" | sed 's/\./\\./g; s/\[/\\[/g; s/\]/\\]/g')"
                current_loop=$(echo "$current_loop" | sed "s@$match@$value@g")
            done

            final_output="$final_output\n$current_loop"
        done

        local loop_block_sed_match="$(_escape_content_for_sed "$loop_block")"
        local final_output_sed="$(_escape_content_for_sed "$final_output")"
        template_content_ref=$(echo "$template_content_ref" | sed -zE "s@${loop_block_sed_match}@${final_output_sed}@g")
        loop_block=$(echo "$template_content_ref" | sed -n '/{#for/,/{\/for}/p' | sed -n '1,/\/for}/p')
    done
}

load_html_template () {
    local template_name=$1
    local context_json_obj=$2

    local template_path=$(get_html_template_absolute_path "$template_name")
    local template_content=$(cat "$template_path")

    _replace_global_variables_values template_content
    _replace_for_loops "$context_json_obj" template_content
    _replace_context_variables "$context_json_obj" template_content

    echo "$template_content"
}

export -f _replace_global_variables_values
export -f _extract_context_variable_value
export -f _replace_context_variables
export -f _escape_content_for_sed
export -f _replace_for_loops
export -f load_html_template