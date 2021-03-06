#!/bin/sh
#
#   Copyright (c) 2022: Jacob.Lundqvist@gmail.com
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-power-zoom
#
#   Version: 0.2.0 2022-04-15
#
#  Common stuff
#
#  Since this is a POSIX script, all variables are global. To ensure that
#  a function does not overwrite a value for a caller, it's good practice
#  to always use function related prefixes on all variable names.
#

#
#  Shorthand, to avoid manually typing package name on multiple
#  locations, easily getting out of sync.
#
plugin_name="tmux-power-zoom"


#
#  If log_file is empty or undefined, no logging will occur,
#  so comment it out for normal usage.
#
# log_file="/tmp/$plugin_name.log"  # Trigger LF to separate runs of this script


#
#  If $log_file is empty or undefined, no logging will occur.
#
log_it() {
    if [ -z "$log_file" ]; then
        return
    fi
    printf "[%s] %s\n" "$(date '+%H:%M:%S')" "$@" >> "$log_file"
}


#
#  Display $1 as an error message in log and as a tmux display-message
#  If no $2 or set to 0, process is not exited
#
error_msg() {
    msg="ERROR: $1"
    exit_code="${2:-0}"

    log_it "$msg"
    tmux display-message "$plugin_name $msg"
    [ "$exit_code" -ne 0 ] && exit "$exit_code"
}


#
#  Aargh in shell boolean true is 0, but to make the boolean parameters
#  more relatable for users 1 is yes and 0 is no, so we need to switch
#  them here in order for assignment to follow boolean logic in caller
#
bool_param() {
    case "$1" in

        "0") return 1 ;;

        "1") return 0 ;;

        "yes" | "Yes" | "YES" | "true" | "True" | "TRUE" )
            #  Be a nice guy and accept some common positives
            log_it "Converted incorrect positive [$1] to 0"
            return 0
            ;;

        "no" | "No" | "NO" | "false" | "False" | "FALSE" )
            #  Be a nice guy and accept some common negatives
            log_it "Converted incorrect negative [$1] to 1"
            return 1
            ;;

        *)
            log_it "Invalid parameter bool_param($1)"
            error_msg "bool_param($1) - should be 0 or 1"
            ;;

    esac
    return 1 # default to False
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
    unset gto_option
    unset gto_default_value
    unset gto_value
}
