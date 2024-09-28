#!/bin/bash

import db/config.sh
import util/math.sh

create_db_table () {
    local table_name=$1
    local -n columns_data=$2

    if [[ -z "$table_name" ]]; then
        return 1
    fi
    
    local columns_config=""
    for key in ${!columns_data[@]}; do
        columns_config="$columns_config
                        $key ${columns_data[$key]},"
    done
    
    columns_config=${columns_config::-1}

    eval "sqlite3 $BASE_DB_PATH '
    CREATE TABLE IF NOT EXISTS $table_name (
        $columns_config
    );
    ' >/dev/null 2>&1"

    return 0
}

add_entry_to_db () {
    local table_name=$1
    local -n values_map=$2

    if [[ -z "$table_name" ]]; then
        echo "0"
        return 1
    fi

    local columns=""
    local values=""

    for key in ${!values_map[@]}; do
        columns="$columns$key,"
        if [[ "$(is_number "${values_map[$key]}")" -eq "1" ]]; then
            values="$values${values_map[$key]},"
        else
            values="$values'${values_map[$key]}',"
        fi
    done

    columns=${columns::-1}
    values=${values::-1}

    local new_entry_id=$(sqlite3 $BASE_DB_PATH "
        INSERT INTO $table_name ($columns) VALUES ($values);
        SELECT last_insert_rowid();
    ")

    new_entry_id=$(echo "$new_entry_id" | awk 'NR==2')

    if [[ -z "$new_entry_id" ]] || [[ "$new_entry_id" -eq "0" ]]; then
        new_entry_id=0
    fi

    echo "$new_entry_id"
    return 0
}

get_db_entry_by_id () {
    local table_name=$1
    local entry_id=$2
    local -n entry_data_name_ref=$3

    if [[ -z "$table_name" ]] || [[ -z "$entry_id" ]]; then
        return 1
    fi

    local columns=$(sqlite3 "$BASE_DB_PATH" "PRAGMA table_info($table_name);" | awk 'NR > 1' | awk -F'|' '{print $2}')
    local -a column_names
    IFS=$'\n' read -r -d '' -a column_names <<< "$columns"

    local query_result=$(sqlite3 "$BASE_DB_PATH" "SELECT * FROM $table_name WHERE id = $entry_id;")
    
    if [[ "$DB_HAS_HEADERS_ON" -eq "1" ]]; then
        query_result="$(echo "$query_result" | awk '{if(NR>1)print}')"
    fi

    if [[ -z "$query_result" ]]; then
        return 1
    fi

    local -a column_values
    IFS='|' read -r -a column_values <<< "$query_result"

    for i in "${!column_names[@]}"; do
        local column_name="${column_names[$i]}"
        local column_value="${column_values[$i]}"
        entry_data_name_ref[$column_name]="$column_value"
    done

    return 0
}

get_list_of_db_entries () {
    local -n entries_list_name_ref=$1
    local table_name=$2
    local num_entries=${3:-10}
    local order_by=${4:-'id'}
    local order_direction=${5:-'ascending'}
    local prev_entry_order_value=${6:-'null'}
    local where_condition=${7:-'1=1'}

    if [[ -z "$table_name" ]]; then
        return 1
    fi

    local columns=$(sqlite3 "$BASE_DB_PATH" "PRAGMA table_info($table_name);" | awk 'NR > 1' | awk -F'|' '{print $2}')
    local -a column_names
    IFS=$'\n' read -r -d '' -a column_names <<< "$columns"

    if [[ "$order_direction" == 'descending' ]]; then
        order_direction="DESC"
    else
        order_direction="ASC"
    fi

    local relative_to_cond=""
    if [[ "$prev_entry_order_value" != "null" ]]; then
        local comparison_sign='>'
        [[ "$order_direction" == "DESC" ]] && comparison_sign='<'
        relative_to_cond="AND $order_by $comparison_sign $prev_entry_order_value"
    fi

    local query_result=$(sqlite3 "$BASE_DB_PATH" "SELECT * FROM $table_name WHERE $where_condition $relative_to_cond ORDER BY $order_by $order_direction LIMIT $num_entries;")
    if [[ "$DB_HAS_HEADERS_ON" -eq "1" ]]; then
        query_result="$(echo "$query_result" | awk '{if(NR>1)print}')"
    fi

    entries_list_name_ref=()
    if [[ -z "$query_result" ]]; then
        return 0
    fi

    local -a row_values
    readarray -t row_values < <(printf "$query_result")

    for i in "${!row_values[@]}"; do
        local -a column_values
        IFS='|' read -r -a column_values <<< "${row_values[$i]}"

        for j in "${!column_names[@]}"; do
            local column_name="${column_names[$j]}"
            local column_value="${column_values[$j]}"
            entries_list_name_ref[$i]="${entries_list_name_ref[$i]}$column_name:$column_value|"
        done
        entries_list_name_ref[$i]=${entries_list_name_ref[$i]::-1}
    done

    return 0
}

update_db_entry_by_id () {
    local table_name=$1
    local update_entry_id=$2
    local -n entry_update_data_name_ref=$3

    local update_data=""

    for key in ${!entry_update_data_name_ref[@]}; do
        local value=${entry_update_data_name_ref[$key]}
        if [[ "$(is_number "$value")" -eq "1" ]]; then
            update_data="$update_data$key = $value, "
        else
            update_data="$update_data$key = '$value', "
        fi
    done

    update_data=${update_data::-2}

    local result=$(sqlite3 "$BASE_DB_PATH" "
        UPDATE $table_name SET $update_data WHERE id = $update_entry_id;
        SELECT changes();
    ")

    local rows_affected=$(echo "$result" | tail -n 1)

    if [[ "$rows_affected" -gt 0 ]]; then
        return 0
    else
        return 1
    fi
}

delete_db_entry_by_id () {
    local table_name=$1
    local delete_entry_id=$2

    if [[ -z "$table_name" ]] || [[ -z "$delete_entry_id" ]]; then
        return 1
    fi

    local result=$(sqlite3 "$BASE_DB_PATH" "
        DELETE FROM $table_name WHERE id = $delete_entry_id;
        SELECT changes();
    "
    )

    local rows_affected=$(echo "$result" | tail -n 1)

    if [ "$rows_affected" -gt 0 ]; then
        return 0
    else
        return 1
    fi
}

clear_db () {
    local tables=$(sqlite3 "$BASE_DB_PATH" ".tables" >/dev/null 2>&1)

    for table in $tables; do
        sqlite3 "$BASE_DB_PATH" "DROP TABLE IF EXISTS $table;" >/dev/null 2>&1
    done
}

export -f create_db_table
export -f add_entry_to_db
export -f get_db_entry_by_id
export -f get_list_of_db_entries
export -f update_db_entry_by_id
export -f delete_db_entry_by_id
export -f clear_db
