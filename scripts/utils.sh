#!/bin/sh
#
#   Copyright (c) 2022: Jacob.Lundqvist@gmail.com
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-power-zoom
#
#   Version: 0.1.0 2022-03-19
#
#  Common stuff
#
#  Since this is a POSIX script, all variables are global. To ensure that
#  a function does not overwrite a value for a caller, it's good practice
#  to always use function related prefixes on all variable names.
#


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
#  Argh in shell bool true is 0, but to make the bool paramas
#  more relatable for users 1 is yes and 0 is no, so we need to switch
#  them here in order for assignment to follow bool logic in caller
#
bool_param() {
    case "$1" in

        "0") return 1 ;;

        "1") return 0 ;;

        "yes" | "Yes" | "YES" | "true" | "True" | "TRUE" )
            #  Be a nice guy and accept some common positives
            log_it "Converted incorrect positive [$1] to 1"
            return 0
            ;;

        "no" | "No" | "NO" | "false" | "False" | "FALSE" )
            #  Be a nice guy and accept some common negatives
            log_it "Converted incorrect negative [$1] to 0"
            return 1
            ;;

        *)
            log_it "Invalid parameter bool_param($1)"
            tmux display "ERROR: bool_param($1) - should be 0 or 1"

    esac
    return 1
}
