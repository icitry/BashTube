#!/bin/bash

declare -gx BASE_HTML_TEMPLATES_PATH
declare -gx HTML_TEMPLATES_CONTEXT_DOMAIN

set_html_templates_dir_path () {
    if ! [[ -z "$BASE_HTML_TEMPLATES_PATH" ]]; then
        return
    fi

    local path=${1:-''}
    BASE_HTML_TEMPLATES_PATH="$path"
}

init_html_templates_dir () {
    if test -d "$BASE_HTML_TEMPLATES_PATH"; then
        return
    fi

    mkdir -p "$BASE_HTML_TEMPLATES_PATH"
}

get_html_template_absolute_path () {
    local template_name=$1
    echo "$BASE_HTML_TEMPLATES_PATH/$template_name"
}

set_context_domain () {
    if ! [[ -z "$HTML_TEMPLATES_CONTEXT_DOMAIN" ]]; then
        return 1
    fi

    local domain=$1

    if ! [[ -z "$domain" ]]; then
        HTML_TEMPLATES_CONTEXT_DOMAIN="$domain"
        return 0;
    fi

    return 1
}

export -f set_html_templates_dir_path
export -f init_html_templates_dir
export -f get_html_template_absolute_path
export -f set_context_domain
