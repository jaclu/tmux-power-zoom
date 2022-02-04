#!/bin/sh
#
#   Copyright (c) 2022: Jacob.Lundqvist@gmail.com
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-power-zoom
#
#   Version: 0.0.1 2022-02-04
#
#  Common stuff
#

get_tmux_option() {
    local option=$1
    local default_value=$2
    local option_value=$(tmux show-option -gqv "$option")
    if [ -z "$option_value" ]; then
        echo "$default_value"
    else
        echo "$option_value"
    fi
}



#
#  If $log_file is empty or undefined, no logging will occur.
#
log_it() {
    if [ -z "$log_file" ]; then
        return
    fi
    printf "%s\n" "$@" >> "$log_file"
}


check_1_0_param() {
    param_name="$1"

    param_value=$(get_tmux_option "$param_name" "0")

    case "$param_value" in
        
        "0" | "1" )  # expected params
            param_verified="$param_value"
	    ;;
        
        "yes" | "Yes" | "YES" | "true" | "True" | "TRUE" )
	    #  Be a nice guy and accept some common positives
            log_it "Converted incorret positive to 1"
            param_verified=1
            ;;
        
        *)
            log_it "Invalid without_prefix value"
            tmux display 'ERROR: "$param_name" should be 0 or 1, was: $param_value'
            exit 0  # Exit 0 wont throw a tmux error            
    esac
}
