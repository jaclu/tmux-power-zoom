#!/bin/sh
#
#   Copyright (c) 2022: Jacob.Lundqvist@gmail.com
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-power-zoom
#
#   Version: 0.1.0 2022-03-03
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

#
#  Generic plugin setting I use to add Notes to plugin keys that are bound
#  This makes this key binding show up when doing <prefix> ?
#  If not set to "Yes", no attempt at adding notes will happen.
#  bind-key Notes were added in tmux 3.1, so should not be used on older versions!
#
use_notes=$(get_tmux_option "@plugin_use_notes" "No")
log_it "use_notes=[$use_notes]"


if [ "$without_prefix" -eq 1 ]; then
    if [ "$use_notes" = "Yes" ]; then
        tmux bind -N "tmux-power-zoom" -n "$trigger_key" run-shell "$SCRIPTS_DIR"/power_zoom.sh
    else
        tmux bind -n "$trigger_key" run-shell "$SCRIPTS_DIR"/power_zoom.sh
    fi
    log_it "Menus bound to: $trigger_key"
else
    if [ "$use_notes" = "Yes" ]; then
        tmux bind -N "tmux-power-zoom" "$trigger_key" run-shell "$SCRIPTS_DIR"/power_zoom.sh
    else
        tmux bind "$trigger_key" run-shell "$SCRIPTS_DIR"/power_zoom.sh
    fi
    log_it "Menus bound to: <prefix> $trigger_key"
fi

if [ "$mouse_zoom" -eq 1 ]; then
    #
    #  First select the mouse-over pane, then trigger zoom, otherwise the
    #  focused pane would get zoomed, and not the clicked one.
    #
    tmux bind -n DoubleClick3Pane "select-pane -t= ; run-shell -t= \"$SCRIPTS_DIR/power_zoom.sh\""
fi
