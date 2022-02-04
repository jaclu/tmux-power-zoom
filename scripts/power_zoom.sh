#!/bin/sh
#
#   Copyright (c) 2022: Jacob.Lundqvist@gmail.com
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-power-zoom
#
#   Version: 0.0.1 2022-02-04
#

power_zoom() {
    primary_pane_id="$(tmux display -p '#D')"
    primary_pane_title="$(tmux display -p '#T')"

    placeholder_title="$primary_pane_id place holder pane"

    placeholder_pane=$(tmux list-panes -a -F "#D #T" | grep "$placeholder_title" | awk '{ print $1 }')

    if [ -n "$placeholder_pane" ]; then
        #
        #  Un-Zoom - move pane back to original location
        #
        tmux join-pane -b -t "$placeholder_pane"
        tmux kill-pane -t "$placeholder_pane"
    else
        #
        #  Zoom it
        #
        if [ "$(tmux list-panes | wc -l)" -eq 1 ]; then
            tmux display "Only one pane in this window!"
            return
        fi
        tmux split-window -b
        tmux select-pane -T "$placeholder_title"
        tmux select-pane -t "$primary_pane_id"
        tmux break-pane
        tmux rename-window "Power Zoom $primary_pane_title ($primary_pane_id)"
    fi
}

power_zoom
