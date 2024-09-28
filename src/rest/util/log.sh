#!/bin/bash

import util/time.sh

log() { 
    local msg=${1:-""}
    local tag=${2:-"GLOBAL"}
    local level=${3:-"DEBUG"}

    if [[ -z "msg" ]]; then
        return 1
    fi

    echo -e "[$(get_current_time_shortform)][$level][$tag]: $msg" >&2;
}

get_execution_stack () {
    local i
    local exec_stack=""
    for (( i=1 ; i <= ${#FUNCNAME[@]}-1 ; i++ )); do
        exec_stack="$exec_stack\n${FUNCNAME[$i]} called at ${BASH_SOURCE[$i]}:${BASH_LINENO[$i-1]}"
    done
    echo $exec_stack
}

export -f log
export -f get_execution_stack
