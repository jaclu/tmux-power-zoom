#!/usr/bin/env bash
#
#   Copyright (c) 2022,2025: Jacob.Lundqvist@gmail.com
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
# log_file=~/tmp/"$plugin_name".log

log_it() {
    #  If $log_file is empty or undefined, no logging will occur.
    if [[ -z "$log_file" ]]; then
        return
    fi
    printf "[%s] %s\n" "$(date '+%H:%M:%S')" "$@" >>"$log_file"
}

error_msg() {
    #
    #  Display $1 as an error message in log and as a tmux display-message
    #  If no $2 or set to 0, process is not exited
    #
    msg="ERROR: $1"
    exit_code="${2:-1}"

    log_it "$msg"
    $TMUX_BIN display-message "$plugin_name $msg"
    sleep 1 # ensure message doesn't get overwritten immeditally
    [[ "$exit_code" -gt 0 ]] && exit "$exit_code"
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

lowercase_it() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

normalize_bool_param() {
    #
    #  Take a boolean style text param and convert it into an actual boolean
    #  that can be used in your code. Example of usage:
    #
    #  normalize_normalize_bool_param "@menus_without_prefix" "$default_no_prefix" &&
    #      cfg_no_prefix=true || cfg_no_prefix=false
    #
    #  $cfg_no_prefix && echo "Don't use prefix"
    #
    local nbp_param="$1"
    local nbp_default="$2" # only used for tmux options
    local nbp_variable_name=""
    local prefix

    # log_it "normalize_normalize_bool_param($nbp_param, $nbp_default) [$nbp_variable_name]"
    [[ "${nbp_param%"${nbp_param#?}"}" = "@" ]] && {
        #
        #  If it starts with "@", assume it is a tmux option, thus
        #  read its value from the tmux environment.
        #  In this case $2 must be given as the default value!
        #
        [[ -z "$nbp_default" ]] && {
            error_msg "normalize_normalize_bool_param($nbp_param) - no default"
        }
        nbp_variable_name="$nbp_param"
        nbp_param="$(tmux_get_option "$nbp_param" "$nbp_default")"
    }

    nbp_param="$(lowercase_it "$nbp_param")"

    case "$nbp_param" in
    #
    #  Handle the unfortunate tradition in the tmux community to use
    #  1 to indicate selected / active.
    #  This means that as far as these booleans go 1 is 0 and 0 is 1, how Orwellian...
    #
    1 | yes | true)
        #  Be a nice guy and accept some common positive notations
        return 0
        ;;

    0 | no | false)
        #  Be a nice guy and accept some common false notations
        return 1
        ;;

    *)
        if [[ -n "$nbp_variable_name" ]]; then
            prefix="$nbp_variable_name=$nbp_param"
        else
            prefix="$nbp_param"
        fi
        error_msg "$prefix - should be yes/true or no/false"
        ;;

    esac

    # Should never get here...
    log_it "Invalid parameter normalize_bool_param($1)"
    error_msg "normalize_normalize_bool_param() - failed to evaluate $nbp_param"
}
