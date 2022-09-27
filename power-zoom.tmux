#!/bin/sh
#
#   Copyright (c) 2022: Jacob.Lundqvist@gmail.com
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-power-zoom
#
#   Version: 0.3.0 2022-09-27
#
#   Dependency: 2.6 - select-pane -T introduced with this version
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

mouse_action="$(get_tmux_option "@power_zoom_mouse_action")"
log_it "mouse_action=[$mouse_action]"

#
#  Generic plugin setting I use to add Notes to plugin keys that are bound
#  This makes this key binding show up when doing <prefix> ?
#  If not set to "Yes", no attempt at adding notes will happen.
#  bind-key Notes were added in tmux 3.1, so should not be used on older versions!
#
if bool_param "$(get_tmux_option "@use_bind_key_notes_in_plugins" "No")"; then
    #  shellcheck disable=SC2154
    note="-Nplugin:$plugin_name"
else
    note=""
fi
log_it "note=[$note]"


if [ "$without_prefix" -eq 1 ]; then
    #  shellcheck disable=SC2154
    $TMUX_BIN bind "$note" -n "$trigger_key" run-shell "$SCRIPTS_DIR"/power_zoom.sh
    log_it "Menus bound to: $trigger_key"
else
    $TMUX_BIN bind "$note" "$trigger_key" run-shell "$SCRIPTS_DIR"/power_zoom.sh
    log_it "Menus bound to: <prefix> $trigger_key"
fi


mouse_cmd="select-pane -t= ; run-shell -t= \"$SCRIPTS_DIR/power_zoom.sh\""


if [ -n "$mouse_action" ]; then
    #
    #  First select the mouse-over pane, then trigger zoom, otherwise the
    #  focused pane would get zoomed, and not the clicked one.
    #
    $TMUX_BIN bind "$note" -n "$mouse_action" "$mouse_cmd"
fi


#
#  Obsolete, will soon be removed!
#
if bool_param "$(get_tmux_option "@power_zoom_mouse" "No")"; then
    mouse_zoom=1
else
    mouse_zoom=0
fi
log_it "mouse_zoom=[$mouse_zoom]"

if [ "$mouse_zoom" -eq 1 ]; then
    #
    #  First select the mouse-over pane, then trigger zoom, otherwise the
    #  focused pane would get zoomed, and not the clicked one.
    #
    $TMUX_BIN bind "$note" -n DoubleClick3Pane "$mouse_cmd"
fi
