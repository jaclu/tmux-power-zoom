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
# shellcheck disable=SC2154


# shellcheck disable=SC1007
CURRENT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# shellcheck disable=SC1091
. "$CURRENT_DIR/utils.sh"

IS_ZOOMED="is_zoomed"
GET_PLACEHOLDER="get_placeholder"
GET_ZOOMED="get_zoomed"

set_pz_status() {
    local value="$1"
    log_it ">> new @power_zoom_state [$value]"
    if [[ -n $value ]]; then
        $TMUX_BIN set-option @power_zoom_state "$value"
    else
        $TMUX_BIN set-option -U @power_zoom_state
    fi
}

read_pz_status() {
    statuses="$($TMUX_BIN show-option -qv @power_zoom_state)"
    echo "$statuses"
}

check_pz_status() {
    case $1 in

        "$IS_ZOOMED" | "$GET_PLACEHOLDER" | "$GET_ZOOMED" ) ;;

        *)
            error_msg "ERROR: check_pz_status - invalid param: [$1]"
            ;;
    esac

    current_pane_id="$($TMUX_BIN display -p '#D')"
    log_it "check_pz_status($1) on $current_pane_id"
    updated_values=""
    do_update=false
    result=""
    pow_zoomed_panes=( $(read_pz_status) )
    #log_it "iterate over: [$pow_zoomed_panes]"
    for pzp in "${pow_zoomed_panes[@]}" ; do
        placeholder="$(echo "$pzp" | cut -d= -f 1)"
        zoomed="$(echo "$pzp" | cut -d= -f 2)"
        #log_it ">> loop pzp[$pzp] - placeholder[$placeholder] zoomed[$zoomed]"
        if [[ $zoomed = "$current_pane_id" ]];  then
            if [[ $1 = "$IS_ZOOMED" ]]; then
                # Since this check won't update the list of zoomed panes
                # its ok to return early
                log_it ">> this is zoomed"
                return  # implicit true
            elif [[ $1 = "$GET_PLACEHOLDER" ]]; then
                result=$placeholder
                do_update=true

                log_it "get placeholder, found it"
                continue  # dont save current pair in the update
            fi
        elif [[ $placeholder = "$current_pane_id" ]] && [[ $1 = "$GET_ZOOMED" ]]; then
            log_it "this is a placeholder for $zoomed"
            result=$zoomed
            break
        fi
        # when unzooming
        #if [[ $placeholder = $current_pane_id ]]; then
        updated_values="$updated_values $placeholder=$zoomed"
    done
    if $do_update; then
        set_pz_status "$updated_values"
    fi
    if [[ -n "$result" ]]; then
        # In this case a string is expected, so the implicit true return
        # has no significance
        echo "$result"
    else
        false
    fi
}

power_zoom() {
    if check_pz_status $IS_ZOOMED ; then
        #
        #  Is a zoomed pane, un-zoom it
        #
        placeholder="$(check_pz_status $GET_PLACEHOLDER)"
        
        if [[ -z $placeholder ]]; then
            error_msg "Placeholder for pane is not listed"
        fi
        $TMUX_BIN join-pane -b -t "$placeholder"
        $TMUX_BIN kill-pane -t "$placeholder"
        return
    fi
    zoomed="$(check_pz_status $GET_ZOOMED)"
    if [[ -n "$zoomed" ]]; then
        if [[ -n "$1" ]]; then
            error_msg "Recursion detected when unzooming"
            exit 1
        fi
        #
        #  Keep code simple, only use one unzoom procedure
        #
        $TMUX_BIN select-window -t $zoomed
        power_zoom recursion
    else
        #
        #  Zoom it!
        #
        if [[ "$($TMUX_BIN list-panes | wc -l)" -eq 1 ]]; then
             error_msg "Can't zoom only pane in a window"             
        fi
        current_pane_id="$($TMUX_BIN display -p '#D')"
        #
        #  the place-holder pane will close when it's process is terminated,
        #  so keep a long sleep going for ever in a loop.
        #  Ctrl-C would exit script and pane would close in case the zoomed pane
        #  is killed and the place-holder is left hanging.
        #
	# shellcheck disable=SC2154
	trigger_key=$(get_tmux_option "@power_zoom_trigger" "$default_key")
        $TMUX_BIN split-window -b "echo; echo \"  $placeholder_title\n  Press [<Prefix> $trigger_key] in this pane to restore it back here...\"; while true ; do sleep 30; done"
        $TMUX_BIN select-pane -T "$placeholder_title"
        placholder_pane_id="$($TMUX_BIN display -p '#D')"
        set_pz_status "$(read_pz_status) $placholder_pane_id=$current_pane_id"
        $TMUX_BIN select-pane -t $current_pane_id
        $TMUX_BIN break-pane  # move it to new window
        $TMUX_BIN rename-window "**POWER ZOOM** ($primary_pane_id)"
    fi
}


       

power_zoom
