#!/usr/bin/env bash
#
#   Copyright (c) 2022,2025: Jacob.Lundqvist@gmail.com
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-power-zoom
#
#   Dependency: 2.6 - select-pane -T introduced with this version
#

# shellcheck disable=SC1007
D_PLUGIN=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

D_SCRIPTS="$D_PLUGIN/scripts"

# shellcheck source=scripts/utils.sh
. "$D_SCRIPTS/utils.sh"

cmd_kb="bind-key"
cmd_m="bind-key"

#
#  Generic plugin setting I use to add Notes to plugin keys that are bound
#  This makes this key binding show up when doing <prefix> ?
#  If not set to "Yes", no attempt at adding notes will happen.
#  bind-key Notes were added in tmux 3.1, so should not be used on older versions!
#
normalize_bool_param "$(get_tmux_option "@use_bind_key_notes_in_plugins" "No")" && {
    # set -- "$@" -N "plugin: $plugin_name"
    note="plugin: $plugin_name"
    cmd_kb+=" -N '$note'"
    cmd_m+=" -N '$note'"
    log_it "Using note: $note"
}

if normalize_bool_param "$(get_tmux_option "@power_zoom_without_prefix" "No")"; then
    # set -- "$@" -n
    cmd_kb+=" -n"
    log_it "Not using prefix"
fi

trigger_key=$(get_tmux_option "@power_zoom_trigger" "$default_key")
cmd_kb+=" $trigger_key run-shell $D_SCRIPTS/power_zoom.sh"
#
#  clear list of zoomed panes, should make it smarter so it leaves currently
#  present items, this will leave them hanging on a conf source, but that
#  is minor compared to the risk of having crash left-overs causing future
#  havoc, the zoomed pane is left intact and dead placeholders can easily be
#  killed.
#
$TMUX_BIN set-option -gu @power_zoom_state

eval "$TMUX_BIN $cmd_kb" || {
    error_msg "Failed to bind plugin trigger"
}
log_it "using trigger: $trigger_key"


#
#  If @power_zoom_mouse_action is defined, also bind a mouse action to this
#
mouse_action="$(get_tmux_option "@power_zoom_mouse_action")"
[[ -z "$mouse_action" ]] && exit 0  # no mouse action defined, setup is done

#
#  First select the mouse-over pane, then trigger zoom, otherwise the
#  focused pane would get zoomed, and not the clicked one.
#
mouse_cmd="select-pane -t= ; run-shell -t= $D_SCRIPTS/power_zoom.sh"

cmd_m+=" -n $mouse_action '$mouse_cmd'"
eval "$TMUX_BIN $cmd_m" || {
    error_msg "Failed to bind plugin mouse action trigger"
}
log_it "using mouse trigger: $mouse_action"
