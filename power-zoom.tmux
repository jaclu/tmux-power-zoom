#!/usr/bin/env bash
#
#   Copyright (c) 2022: Jacob.Lundqvist@gmail.com
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-power-zoom
#
#   Dependency: 2.6 - select-pane -T introduced with this version
#
# shellcheck disable=SC2154


# shellcheck disable=SC1007
CURRENT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

SCRIPTS_DIR="$CURRENT_DIR/scripts"

# shellcheck disable=SC1091
. "$SCRIPTS_DIR/utils.sh"


#
#  By printing a NL and date, its easier to keep separate runs apart
#
log_it ""
log_it "$(date)"

options=""
#
#  Generic plugin setting I use to add Notes to plugin keys that are bound
#  This makes this key binding show up when doing <prefix> ?
#  If not set to "Yes", no attempt at adding notes will happen.
#  bind-key Notes were added in tmux 3.1, so should not be used on older versions!
#
if bool_param "$(get_tmux_option "@use_bind_key_notes_in_plugins" "No")"; then
    options+=" -N plugin:$plugin_name"
fi

mouse_action="$(get_tmux_option "@power_zoom_mouse_action")"

if [[ -n "$mouse_action" ]]; then
    #
    #  First select the mouse-over pane, then trigger zoom, otherwise the
    #  focused pane would get zoomed, and not the clicked one.
    #

    # shellcheck disable=SC2089
    mouse_cmd="select-pane -t= \; run-shell -t= \"$SCRIPTS_DIR/power_zoom.sh\""
    # shellcheck disable=SC2086,2090  #options & mouse_cmd cant be quoted
    $TMUX_BIN bind $options -n "$mouse_action" $mouse_cmd
    log_it "Mouse action: $mouse_action"
fi

trigger_key=$(get_tmux_option "@power_zoom_trigger" "$default_key")
log_it "trigger_key=[$trigger_key]"

if bool_param "$(get_tmux_option "@power_zoom_without_prefix" "No")"; then
    options+=" -n"
    log_it "Not using prefix"
fi

#
#  clear list of zoomed panes, should make it smarter so it leaves currently
#  present items, this will leave them hanging on a conf source, but that
#  is minor compared to the risk of having crash left-overs causing future
#  havoc, the zoomed pane is left intact and dead placeholders can easily be
#  killed.
#
$TMUX_BIN set-option @power_zoom_state ""

# shellcheck disable=SC2086  #options cant be quoted
$TMUX_BIN bind $options "$trigger_key" run-shell "$SCRIPTS_DIR"/power_zoom.sh
