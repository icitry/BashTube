#!/bin/bash

get_json_base_value () {
    local json_obj="$1"
    local json_key="$2"

    local value=$(eval "echo '$json_obj' | jq -r '.$json_key'")
    echo "$value"
}

get_json_nested_base_value () {
    local json_obj="$1"
    local value_identifier="$2"

    local value=$(jq -r ".$value_identifier" <<< "$json_obj")
    echo "$value"
}

get_json_array_value () {
    local json_obj="$1"
    local json_key="$2"

    echo "$json_obj" | jq -r ".$json_key[]"
}

get_json_array_index_value () {
    local json_obj="$1"
    local json_key="$2"
    local index="$3"

    local value=$(eval "echo '$json_string' | jq -r '.$key[$index]'")
}

get_json_array_items () {
    local json_obj="$1"
    local -n array_items_name_ref=$2

    local array_str="$(echo "$json_obj" | jq -cr '.[]')"

    if ! [[ -z "$array_str" ]]; then
        mapfile -t array_items_name_ref <<< "$array_str"
    fi
}

get_json_keys () {
    local -n json_obj_keys_array_name_ref=$1
    local json_obj="$2"
 
    local res="$(echo "$json_obj" | jq -r 'keys[]' | tr '\n' ' ')"

    IFS=$' \t\n' read -r -a json_obj_keys_array_name_ref <<< "$res"
}

convert_object_to_json () {
    declare -n obj_to_json_ref=$1

    local jq_input=$(for key in "${!obj_to_json_ref[@]}"; do
        echo "\"$key\":\"${obj_to_json_ref[$key]}\""
    done | paste -sd "," -)

    local res=$(eval "echo '{$jq_input}' | jq .")
    echo "$res"
}

convert_array_to_json() {
    local -n input_array=$1

    local items_str=""

    for item in "${input_array[@]}"; do
        items_str="$items_str$item,"
    done

    if ! [[ -z "$items_str" ]]; then
        items_str=${items_str::-1}
    fi

    items_str="[$items_str]"
    
    local res=$(echo "$items_str" | jq . )

    echo "$res"
}

export -f get_json_base_value
export -f get_json_nested_base_value
export -f get_json_array_value
export -f get_json_array_index_value
export -f get_json_array_items
export -f get_json_keys
export -f convert_object_to_json
export -f convert_array_to_json
