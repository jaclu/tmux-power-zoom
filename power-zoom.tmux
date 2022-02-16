#!/bin/sh
#
#   Copyright (c) 2022: Jacob.Lundqvist@gmail.com
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-power-zoom
#
#   Version: 0.0.3 2022-02-16
#

# shellcheck disable=SC1007
CURRENT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

SCRIPTS_DIR="$CURRENT_DIR/scripts"

# shellcheck disable=SC1091
. "$SCRIPTS_DIR/utils.sh"


#
#  By using Z as default we don't overwrite the default zoom binding
#  unless the caller actually want this to happen.
#
default_key="Z"


#
#  Make it easy to see when a log run occurred, also makes it easier
#  to separate runs of this script
#
log_it ""  # Trigger LF to separate runs of this script
log_it "$(date)"



trigger_key=$(get_tmux_option "@power_zoom_trigger" "$default_key")
log_it "trigger_key=[$trigger_key]"

# shellcheck disable=SC2154
without_prefix=$(check_1_0_param "@power_zoom_without_prefix")
log_it "without_prefix=[$without_prefix]"

mouse_zoom=$(check_1_0_param "@power_zoom_mouse")
log_it "mouse_zoom=[$mouse_zoom]"



if [ "$without_prefix" -eq 1 ]; then
    tmux bind -n "$trigger_key" run-shell "$SCRIPTS_DIR"/power_zoom.sh
    log_it "Menus bound to: $trigger_key"
else
    tmux bind    "$trigger_key" run-shell "$SCRIPTS_DIR"/power_zoom.sh
    log_it "Menus bound to: <prefix> $trigger_key"
fi

if [ "$mouse_zoom" -eq 1 ]; then
    #
    #  First select the mouse-over pane, then trigger zoom, otherwise the
    #  focused pane would get zoomed, and not the clicked one.
    #
    tmux bind -n DoubleClick3Pane "select-pane -t= ; run-shell -t= \"$SCRIPTS_DIR/power_zoom.sh\""
fi
