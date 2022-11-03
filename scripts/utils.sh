#!/usr/bin/env bash
#
#   Copyright (c) 2022: Jacob.Lundqvist@gmail.com
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-power-zoom
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
#  By using Z as default we don't overwrite the default zoom binding (z)
#  unless the caller actually want this to happen.
#
default_key="Z"

#
#  I use an env var TMUX_BIN to point at the current tmux, defined in my
#  tmux.conf, in order to pick the version matching the server running.
#  If not found, it is set to whatever is in path, so should have no negative
#  impact. In all calls to tmux I use $TMUX_BIN instead in the rest of this
#  plugin.
#
[[ -z "$TMUX_BIN" ]] && TMUX_BIN="tmux"


#
#  If log_file is empty or undefined, no logging will occur,
#  so comment it out for normal usage.
#
# log_file="/tmp/$plugin_name.log"  # Trigger LF to separate runs of this script


#
#  If $log_file is empty or undefined, no logging will occur.
#
log_it() {
    if [[ -z "$log_file" ]]; then
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
    $TMUX_BIN display-message "$plugin_name $msg"
    [[ "$exit_code" -ne 0 ]] && exit "$exit_code"
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
            return 0
            ;;

        "no" | "No" | "NO" | "false" | "False" | "FALSE" )
            #  Be a nice guy and accept some common negatives
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
    local option
    local default_value
    local value

    option=$1
    default_value=$2
    value=$($TMUX_BIN show-option -gqv "$option")
    if [[ -z "$value" ]]; then
        echo "$default_value"
    else
        echo "$value"
    fi
}
