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
    log_it "set_pz_status($value)"
    $TMUX_BIN set-option @power_zoom_state "$value"
}

read_pz_status() {
    statuses="$($TMUX_BIN show-option -qv @power_zoom_state)"
    echo "$statuses"
}

check_pz_status() {
    local this_id
    local updated_values
    local do_update
    local result
    local pow_zoomed_panes
    local placeholder
    local zoomed

    case $1 in

    "$IS_ZOOMED" | "$GET_PLACEHOLDER" | "$GET_ZOOMED") ;;

    *)
        error_msg "ERROR: check_pz_status - invalid param: [$1]"
        ;;
    esac

    this_id="$($TMUX_BIN display -p '#D')"
    updated_values=""
    do_update=false
    result=""
    pow_zoomed_panes=($(read_pz_status))
    for pzp in "${pow_zoomed_panes[@]}"; do
        placeholder="$(echo "$pzp" | cut -d= -f 1)"
        zoomed="$(echo "$pzp" | cut -d= -f 2)"
        if [[ $zoomed = "$this_id" ]]; then
            if [[ $1 = "$IS_ZOOMED" ]]; then
                # Since this check won't update the list of zoomed panes
                # its ok to return early
                return # implicit true
            elif [[ $1 = "$GET_PLACEHOLDER" ]]; then
                result=$placeholder
                do_update=true
                #  this will result in unzooming, so dont save current pair
                #  in the update
                continue
            fi
        elif [[ $placeholder = "$this_id" ]] && [[ $1 = "$GET_ZOOMED" ]]; then
            result=$zoomed
            #  wont be doing updates this run, this will just trigger recursion
            #  by the caller, when unzooming and list update will happen,
            #  so no need to complete the loop
            break
        fi
        updated_values="$updated_values $placeholder=$zoomed"
    done
    $do_update && set_pz_status "$updated_values"
    if [[ -n "$result" ]]; then
        # In this case a string is expected, so the implicit true return
        # has no significance
        echo "$result"
    else
        false
    fi
}

power_zoom() {
    if check_pz_status "$IS_ZOOMED"; then
        log_it "was zoomed"
        #
        #  Is a zoomed pane, un-zoom it
        #
        placeholder="$(check_pz_status "$GET_PLACEHOLDER")"

        if [[ -z $placeholder ]]; then
            error_msg "Placeholder for pane is not listed"
        fi
        $TMUX_BIN join-pane -b -t "$placeholder"
        $TMUX_BIN kill-pane -t "$placeholder"
        return
    fi
    zoomed="$(check_pz_status "$GET_ZOOMED")"
    if [[ -n "$zoomed" ]]; then
        log_it "was placeholder"
        if [[ -n "$1" ]]; then
            error_msg "Recursion detected when unzooming"
            exit 99
        fi
        #
        #  Keep code simple, only use one unzoom procedure
        #
        $TMUX_BIN select-window -t "$zoomed"
        power_zoom recursion
    else
        #
        #  Zoom it!
        #
        log_it "will zoom"
        if [[ "$($TMUX_BIN list-panes | wc -l)" -eq 1 ]]; then
            error_msg "Can't zoom only pane in a window"
            exit 0
        fi
        this_id="$($TMUX_BIN display -p '#D')"
        #
        #  the place-holder pane will close when it's process is terminated,
        #  so keep a long sleep going for ever in a loop.
        #  Ctrl-C would exit script and pane would close in case the zoomed pane
        #  is killed and the place-holder is left hanging.
        #
        # shellcheck disable=SC2154
        trigger_key=$(get_tmux_option "@power_zoom_trigger" "$default_key")

        #
        #  What an unexpected pain, doing a while loop in a sub shell fails if
        #  the shel is fish. Luckily in this case I could wrap it in /bin/sh -c "foo"
        #
        $TMUX_BIN split-window -b "echo; \
            echo \"  placeholder for zoomed pane ${this_id}\";  \
            echo ; echo \"  You can press <Prefix> $trigger_key\";  \
            echo \"  in this pane to restore it back here...\";  \
            /bin/sh -c \"while true ; do sleep 300; done\""
        $TMUX_BIN select-pane -T "$placeholder_title"
        placholder_pane_id="$($TMUX_BIN display -p '#D')"
        set_pz_status "$(read_pz_status) $placholder_pane_id=$this_id"
        $TMUX_BIN select-pane -t "$this_id"
        $TMUX_BIN break-pane # move it to new window
        $TMUX_BIN rename-window "ZOOMED $this_id"
    fi
}

power_zoom
