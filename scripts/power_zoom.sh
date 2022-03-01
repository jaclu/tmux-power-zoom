#!/bin/sh
#
#   Copyright (c) 2022: Jacob.Lundqvist@gmail.com
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-power-zoom
#
#   Version: 0.1.0 2022-02-28
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
    [ "$recursion" != "" ] && log_it "power_zoom($recursion) triggered" 

    primary_pane_id="$(tmux display -p '#D')"
    primary_pane_title="$(tmux display -p '#T')"

    placeholder_stub="=== POWER ZOOM === place-holder for pane:"
    placeholder_title="$placeholder_stub $primary_pane_id"

    log_it "Checking for this place-holder: [$placeholder_title]"
    placeholder_pane=$(tmux list-panes -a -F "#D #T" | grep "$placeholder_title" | awk '{ print $1 }')

    if [ -n "$placeholder_pane" ]; then
        #
        #  Found a place-holder for current pane, move it there and delete
        #  the place-holder
        #
        log_it "Found a matching place-holder, move this pane there and delete place-holder"
        tmux join-pane -b -t "$placeholder_pane"
        tmux kill-pane -t "$placeholder_pane"
    else
        #
        #  Zoom this to new window
        #
        if [ "$(tmux list-panes | wc -l)" -eq 1 ]; then
            msg="Cant zoom only pane in a window"
            log_it "$msg"
            tmux display "$msg"
            return 0
        fi
        if [ "$(tmux display -p '#T' | grep "$placeholder_stub")" != "" ]; then
            log_it "This is a Power-Zoom place-holder!"
            #
            # go to the referred pane, and run power_zoom again to restore it.
            #
            if [ "$recursion" -ne "" ]; then
                msg="power_zoom is entering recursion, aborting"
                log_it "$msg"
                tmux display "$msg"
                return 0
            fi
            pane_id="$(tmux display -p '#T'| awk '{print $8}')"
            log_it "pane_id: [$pane_id]"
            if ! tmux select-window -t "$pane_id"; then
                msg="Failed to find window with Zoomed pane: $pane_id"
                log_it "$msg"
                tmux display "$msg"
                return 0
            fi

            if ! tmux select-pane -t  "$pane_id"; then
                msg="Failed to find Zoomed pane: $pane_id"
                log_it "$msg"
                tmux display "$msg"
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
        tmux split-window -b "echo; echo \"  $placeholder_title\"; while true ; do sleep 30; done"
        tmux select-pane -T "$placeholder_title"
        tmux select-pane -t "$primary_pane_id"
        tmux break-pane  # move it to new window
        tmux rename-window "**POWER ZOOM** $primary_pane_title ($primary_pane_id)"
    fi
    return 0
}

power_zoom
