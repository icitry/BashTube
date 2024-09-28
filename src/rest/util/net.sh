#!/bin/bash

get_current_ip_address () {
    if [[ "$IS_DEBUG" -eq "1" ]]; then
        echo "http://127.0.0.1:$HTTP_SERVER_PORT"
    else
        local addr="$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')"
        echo "http://$addr:$HTTP_SERVER_PORT"
    fi
}

export -f get_current_ip_address
