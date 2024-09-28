#!/bin/bash

declare -gx BASE_DB_PATH
declare -gx DB_HAS_HEADERS_ON

set_db_path () {
    if ! [[ -z "$BASE_DB_PATH" ]]; then
        return
    fi

    local path=${1:-''}
    BASE_DB_PATH="$path"
}

init_db () {
    if test -f "$BASE_DB_PATH"; then
        return
    fi

    local path_dir="$(dirname $BASE_DB_PATH)"
    mkdir -p "$path_dir" && touch "$BASE_DB_PATH"
}

check_db_has_headers_enabled () {
    sqlite3 "$BASE_DB_PATH" "CREATE TABLE IF NOT EXISTS dummy_table_to_test_headers (id INTEGER PRIMARY KEY, name TEXT);" >/dev/null 2>&1

    sqlite3 "$BASE_DB_PATH" "INSERT INTO dummy_table_to_test_headers (name) VALUES ('dummy');" >/dev/null 2>&1
    
    local output=$(sqlite3 "$BASE_DB_PATH" "SELECT * FROM dummy_table_to_test_headers LIMIT 1;" 2>&1)

    local has_headers_on="$(echo "$output" | grep 'id|name')"

    if ! [[ -z "$has_headers_on" ]]; then
        DB_HAS_HEADERS_ON=1
    else
        DB_HAS_HEADERS_ON=0
    fi
}

export -f set_db_path
export -f init_db
export -f check_db_has_headers_enabled
