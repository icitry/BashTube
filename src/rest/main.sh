#!/bin/bash

init_rest () {    
    local original_script_dir="$( cd "$( dirname "${BASH_SOURCE[-1]}" )" &> /dev/null && pwd )" 
    local script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

    source $script_dir/meta/import_manager.sh
    init_import_manager $script_dir
    
    # init persistent files/directories
    import db/config.sh
    set_db_path "$original_script_dir/db.sqlite3"
    init_db
    check_db_has_headers_enabled
    
    import storage/config.sh
    set_storage_path "$original_script_dir/storage"
    init_storage
    set_static_dir_path "$original_script_dir/static"
    init_static_dir

    import templates/config.sh
    set_html_templates_dir_path "$original_script_dir/templates"
    init_html_templates_dir
    
    # run modules' global init instructions
    import controller/controller.sh
    import controller/response.sh
}

init_rest $@

export -f init_rest
