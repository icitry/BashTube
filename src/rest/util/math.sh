#!/bin/bash

is_number () {
    local number="$1"
    local re='^[+-]?[0-9]+([.][0-9]+)?$'

    if ! [[ "$number" =~ $re ]] ; then
        echo 0
    else
        echo 1
    fi
}