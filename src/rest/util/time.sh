#!/bin/bash

get_current_time () {
    local current_time=$(date +"%a, %d %b %Y %H:%M:%S %Z")
    echo "$current_time"
}

get_current_time_shortform () {
    local current_time=$(date +"%d/%m/%y %H:%M:%S")
    echo "$current_time"
}

export -f get_current_time
export -f get_current_time_shortform
