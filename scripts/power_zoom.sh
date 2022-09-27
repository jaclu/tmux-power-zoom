#!/usr/bin/env bash
#
#   Copyright (c) 2022: Jacob.Lundqvist@gmail.com
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-power-zoom
#
#   Version: 0.1.6 2022-09-27
#
#   Tracking the placeholder pane by its pane title, this works regardless
#   if pane titles are displayed or not.
#
# shellcheck disable=SC1007
CURRENT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# shellcheck disable=SC1091
. "$CURRENT_DIR/utils.sh"



power_zoom() {
    recursion="$1"
    [[ "$recursion" != "" ]] && log_it "power_zoom($recursion) triggered"

    # shellcheck disable=SC2154
    primary_pane_id="$($TMUX_BIN display -p '#D')"
    primary_pane_title="$($TMUX_BIN display -p '#T')"

    placeholder_stub="=== POWER ZOOM === place-holder for pane:"
    placeholder_title="$placeholder_stub $primary_pane_id"

    log_it "Checking for this place-holder: [$placeholder_title]"
    placeholder_pane=$($TMUX_BIN list-panes -a -F "#D #T" | grep "$placeholder_title" | awk '{ print $1 }')

    if [[ -n "$placeholder_pane" ]]; then
        #
        #  Found a place-holder for current pane, move it there and delete
        #  the place-holder
        #
        log_it "Found a matching place-holder, move this pane there and delete place-holder"
        $TMUX_BIN join-pane -b -t "$placeholder_pane"
        $TMUX_BIN kill-pane -t "$placeholder_pane"
    else
        #
        #  Zoom this to new window
        #
        if [[ "$($TMUX_BIN list-panes | wc -l)" -eq 1 ]]; then
             error_msg "Can't zoom only pane in a window"
            return 0
        fi
        if [[ "$($TMUX_BIN display -p '#T' | grep "$placeholder_stub")" != "" ]]; then
            #  shellcheck disable=SC2154
            log_it "This is a $plugin_name place-holder!"
            #
            # go to the referred pane, and run power_zoom again to restore it.
            #
            if [[ "$recursion" -ne "" ]]; then
                error_msg "power_zoom is entering repeated recursion, aborting"
                return 0
            fi
            pane_id="$($TMUX_BIN display -p '#T'| awk '{print $8}')"
            log_it "pane_id: [$pane_id]"
            if ! $TMUX_BIN select-window -t "$pane_id"; then
                error_msg "Failed to find window with Zoomed pane: $pane_id"
                return 0
            fi

            if ! $TMUX_BIN select-pane -t  "$pane_id"; then
                error_msg "Failed to find Zoomed pane: $pane_id"
                return 0
            fi
            power_zoom recursion
            return 0
        fi
        #
        #  the place-holder pane will close when it's process is terminated,
        #  so keep a long sleep going for ever in a loop.
        #  Ctrl-C would exit script and pane would close in case the zoomed pane
        #  is killed and the place-holder is left hanging.
        #
        log_it "Zoom active pane to new window"
	# shellcheck disable=SC2154
	trigger_key=$(get_tmux_option "@power_zoom_trigger" "$default_key")
        $TMUX_BIN split-window -b "echo; echo \"  $placeholder_title\n  Press [<Prefix> $trigger_key] in this pane to restore it back here...\"; while true ; do sleep 30; done"
        $TMUX_BIN select-pane -T "$placeholder_title"
        $TMUX_BIN select-pane -t "$primary_pane_id"
        $TMUX_BIN break-pane  # move it to new window
        $TMUX_BIN rename-window "**POWER ZOOM** $primary_pane_title ($primary_pane_id)"
    fi
    return 0
}

power_zoom
