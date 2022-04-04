#!/bin/sh
#
#   Copyright (c) 2022: Jacob.Lundqvist@gmail.com
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-power-zoom
#
#   Version: 0.1.2 2022-04-04
#

# shellcheck disable=SC1007
CURRENT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

SCRIPTS_DIR="$CURRENT_DIR/scripts"

# shellcheck disable=SC1091
. "$SCRIPTS_DIR/utils.sh"


#
#  By using Z as default we don't overwrite the default zoom binding (z)
#  unless the caller actually want this to happen.
#
default_key="Z"


#
#  By printing a NL and date, its easier to keep separate runs apart
#
log_it ""
log_it "$(date)"


trigger_key=$(get_tmux_option "@power_zoom_trigger" "$default_key")
log_it "trigger_key=[$trigger_key]"


if bool_param "$(get_tmux_option "@power_zoom_without_prefix" "No")"; then
    without_prefix=1
else
    without_prefix=0
fi
log_it "without_prefix=[$without_prefix]"


if bool_param "$(get_tmux_option "@power_zoom_mouse" "No")"; then
    mouse_zoom=1
else
    mouse_zoom=0
fi
log_it "mouse_zoom=[$mouse_zoom]"


#
#  Generic plugin setting I use to add Notes to plugin keys that are bound
#  This makes this key binding show up when doing <prefix> ?
#  If not set to "Yes", no attempt at adding notes will happen.
#  bind-key Notes were added in tmux 3.1, so should not be used on older versions!
#
if bool_param "$(get_tmux_option "@plugin_use_notes" "No")"; then
    use_notes=1
else
    use_notes=0
fi
log_it "use_notes=[$use_notes]"


if [ "$without_prefix" -eq 1 ]; then
    if [ "$use_notes" -eq 1 ]; then
        tmux bind -N "$plugin_name" -n "$trigger_key" run-shell "$SCRIPTS_DIR"/power_zoom.sh
    else
        tmux bind -n "$trigger_key" run-shell "$SCRIPTS_DIR"/power_zoom.sh
    fi
    log_it "Menus bound to: $trigger_key"
else
    if [ "$use_notes" -eq 1 ]; then
        tmux bind -N "$plugin_name" "$trigger_key" run-shell "$SCRIPTS_DIR"/power_zoom.sh
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
