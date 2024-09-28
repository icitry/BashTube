#!/bin/bash

declare -gax MANAGER_IMPORT_ARRAY
declare -gx REST_PACKAGE_BASE_DIR="$(pwd)/"
declare -gx CHILD_ENV_INIT_FILE_PATH

_is_imported() {
    local import_requested="${1}"
    for imported in "${MANAGER_IMPORT_ARRAY[@]}"; do
        [[ "${import_requested}" == "${imported}" ]] && return 0
    done
    return 1
}

import() {
    local to_source=("${@}")

    for script in "${to_source[@]}"; do
        if ! _is_imported "${script}" &&
            [[ -f "${REST_PACKAGE_BASE_DIR}${script}" ]]; then
            MANAGER_IMPORT_ARRAY+=("${script}")
            builtin source "${REST_PACKAGE_BASE_DIR}${script}"
        else
            continue
        fi
    done
}

init_import_manager () {
    REST_PACKAGE_BASE_DIR=$1
    if [[ "${REST_PACKAGE_BASE_DIR: -1}" != "/" ]]; then
        REST_PACKAGE_BASE_DIR="${REST_PACKAGE_BASE_DIR}/"
    fi
}

init_child_env_imports_file () {
    CHILD_ENV_IMPORTS_FILE_PATH="${REST_PACKAGE_BASE_DIR}meta/child_env_imports.tmp"
    mkdir -p "$(dirname $CHILD_ENV_IMPORTS_FILE_PATH)"
    touch "$CHILD_ENV_IMPORTS_FILE_PATH"
    > $CHILD_ENV_IMPORTS_FILE_PATH
    export CHILD_ENV_IMPORTS_FILE_PATH
}

clean_child_env_imports_file () {
    rm -f $CHILD_ENV_IMPORTS_FILE_PATH
}

_generate_import_manager_imports_for_child_env () {
    local env_file_path=$1
    declare -p MANAGER_IMPORT_ARRAY >> "$env_file_path"
}

export -f _is_imported
export -f import
export -f init_import_manager
export -f init_child_env_imports_file