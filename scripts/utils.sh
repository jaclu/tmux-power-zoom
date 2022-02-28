#!/bin/sh
#
#   Copyright (c) 2022: Jacob.Lundqvist@gmail.com
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-power-zoom
#
#   Version: 0.0.4 2022-02-28
#
#  Common stuff
#
#  Since this is a POSIX script, all variables are global. To ensure that
#  a function does not overwrite a value for a caller, it's good practice
#  to always use function related prefixes on all variable names.
#

get_tmux_option() {
    gto_option=$1
    gto_default_value=$2
    gto_value=$(tmux show-option -gqv "$gto_option")
    if [ -z "$gto_value" ]; then
        echo "$gto_default_value"
    else
        echo "$gto_value"
    fi
}



#
#  If log_file is empty or undefined, no logging will occur, 
#  so comment it out for normal usage.
#
#log_file="/tmp/tmux-power-zoom.log"

log_it() {
    if [ -z "$log_file" ]; then
        return
    fi
    printf "%s\n" "$@" >> "$log_file"
}


#
#  If value is not defined, set it to 0
#  If Value is set to be 1/0 use that value
#  Accept a few alternative common positives as 1
#  Display error for other values
#
check_1_0_param() {
    c10p_option="$1"
    c10p_value=$(get_tmux_option "$c10p_option" "0")

    case "$c10p_value" in
        
        "0" | "1" )  # expected values
            echo "$c10p_value"
	    ;;
        
        "yes" | "Yes" | "YES" | "true" | "True" | "TRUE" )
	    #  Be a nice guy and accept some common positives
            log_it "Converted incorrect positive to 1"
            # shellcheck disable=SC2034
            echo 1
            ;;
        
        *)
            log_it "Invalid $c10p_option value - [$c10p_value]"
            tmux display "ERROR: \"$c10p_option\" should be 0 or 1, was: $c10p_value"
            exit 0  # Exit 0 wont throw a tmux error            
    esac
}
