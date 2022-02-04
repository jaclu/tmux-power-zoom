#!/bin/sh
#
#   Copyright (c) 2022: Jacob.Lundqvist@gmail.com
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-menus
#
#   Version: 0.0.1 2022-02-04
#


CURRENT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

SCRIPTS_DIR="$CURRENT_DIR/scripts"

. "$SCRIPTS_DIR/utils.sh"

#
#  In shell script unlike in tmux, backslash needs to be doubled inside quotes.
#
default_key="Z"


#
#  If log_file is empty or undefined, no logging will occur, so normally
#  comment it out for normal usage.
#
#log_file="/tmp/tmux-power-zoom.log"



#
#  Make it easy to see when a log run occured, also makes it easier
#  to separate runs of this script
#
log_it ""  # Trigger LF to separate runs of this script
log_it "$(date)"


trigger_key=$(get_tmux_option "@power_zoom_trigger" "$default_key")
log_it "trigger_key=[$trigger_key]"

check_1_0_param "@power_zoom_without_prefix"
without_prefix="$param_verified"
log_it "without_prefix=[$without_prefix]"

check_1_0_param "@power_zoom_mouse"
mouse_zoom="$param_verified"
log_it "mouse_zoom=[$mouse_zoom]"


if [ "$without_prefix" -eq 1 ]; then
    tmux bind -n "$trigger_key" run-shell "$SCRIPTS_DIR"/power_zoom.sh
    log_it "Menus bound to: $trigger_key"
else
    tmux bind    "$trigger_key" run-shell "$SCRIPTS_DIR"/power_zoom.sh
    log_it "Menus bound to: <prefix> $trigger_key"
fi

if [ "$mouse_zoom" -eq 1 ]; then
    tmux bind -n DoubleClick3Pane run-shell "$SCRIPTS_DIR"/power_zoom.sh
fi
