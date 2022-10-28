#!/usr/bin/env bash
#
#   Copyright (c) 2022: Jacob.Lundqvist@gmail.com
#   License: MIT
#
#   Part of https://github.com/jaclu/tmux-power-zoom
#
#   Tracking the placeholder pane by its pane title, this works regardless
#   if pane titles are displayed or not.
#
# shellcheck disable=SC1007
CURRENT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# shellcheck disable=SC1091
. "$CURRENT_DIR/utils.sh"

IS_ZOOMED="is_zoomed"
GET_ORIGIN="get_origin"
GET_ZOOMED="get_zoomed"


set_pz_status() {
    local value="$1"
    [[ -z $value ]] && error_msg "set_pz() missing param"

    $TMUX_BIN set-option @power_zoom_state "$value"
}

get_pz_status() {
    echo "$($TMUX_BIN show-option -q @power_zoom_state)"
}

pz_status() {
    case $1 in

        $IS_ZOOMED | $GET_ORIGIN | $GET_ZOOMED ) ;;

        *)
            error_msg "ERROR: examine_pz_status - invalid param: [$1]"
            ;;
    esac

    current_pane_id="$($TMUX_BIN display -p '#D')"
    updated_values=""
    do_update=false
    pow_zoomed_panes=get_pz_status
    for pzp in "${pow_zoomed_panes[@]}" ; do
        id="$(echo $pzp | cut -d= -f 1)"
        source="$(echo $pzp | cut -d= -f 2)"
        if [[ $id = $current_pane_id ]]; then
            [[ $1 = $IS_ZOOMED ]] && return true
            if [[ $1 = $GET_ORIGIN ]]; then
                result=$source
                do_update=true
            fi
        fi
        if [[ $source = $current_pane_id ]]; then
            result=$id
            do_update=true
        fi
        updated_values="$updated_values $id=$source"
    done
    if do_update; then
        set_pz "$updated_values"
    fi
    if [[ -n $result ]]; then
        return $result
    else
        return false
    fi
}

power_zoom() {
    if pz_status $IS_ZOOMED ; then
        #
        #  Is a zoomed pane, un-zoom it
        #
        origin=pz_status $GET_ORIGIN
        if [[ -z $origin ]]; then
            error_msg "ERROR: Original location for pane is not present"
        fi
        log_it "Found a matching place-holder, move this pane there and delete place-holder"
        $TMUX_BIN join-pane -b -t "$origin"
        $TMUX_BIN kill-pane -t "$origin"
        return
    fi
    zoomed_pane=pz_status $GET_ZOOMED
    if [[ -n $zoomed_pane ]]l then
        unzoom_it_here
    else
        #
        #  Zoom it!
        #
        if [[ "$($TMUX_BIN list-panes | wc -l)" -eq 1 ]]; then
             error_msg "Can't zoom only pane in a window"
            return 0
        fi
        current_pane_id="$($TMUX_BIN display -p '#D')"
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
        $TMUX_BIN select-pane -t "$current_pane_id"
        $TMUX_BIN break-pane  # move it to new window
        $TMUX_BIN rename-window "**POWER ZOOM** $primary_pane_title ($primary_pane_id)"
        
    fi
}


       
unzoom_it_here() {
    #
    #  Not done!
    #
        #
        #  Is placeholder for a power-zoomed pane, unzom it into this location
        #
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
}



old_power_zoom() {
    recursion="$1"
    [[ "$recursion" != "" ]] && log_it "power_zoom($recursion) triggered"

    #
    #  Format "z1=o1 z2=o2"
    #
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
