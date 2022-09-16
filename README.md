# Tmux-Power-Zoom

Zoom pane to separate window, and un-zoom back into the original location.

This way you can open other panes whilst focusing on the zoomed pane, without
risking getting a crowded mess of panes.

You can also restore by triggering the power-zoom action on the place-holder
pane.

## Purpose

Often when zooming a pane, working in it for a while and then figure out
a new pane is needed to check something, the zoomed state is forgotten.
When opening a new pane this way, the new pane becomes squeezed in next
to the original pane, often far to small to be practically usable.

This plugin zooms panes into a new window and makes it convenient to open support
panes. Hitting Smart Zoom again unzooms and move the pane back to it's
original location. The temp window closes, if no other panes are present.

The temp windows name uses title and ID of the zoomed pane, so that if other
panes were open and left running, there is a hint about
the purpose of that window.

## Usage

Hit `<prefix>` + `@power_zoom_trigger` to toggle Power Zoom.
If `@power_zoom_mouse` is enabled, right double click also toggles Power Zoom.

## Install

### Dependencies

`tmux 2.6` or higher.

### Installation with [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) (recommended)

Add plugin to the list of TPM plugins in `.tmux.conf`:

```tmux
set -g @plugin 'jaclu/tmux-power-zoom'
```

Hit `prefix + I` to fetch the plugin and source it.

### Manual installation

Clone the repo:

```bash
git clone https://github.com/jaclu/tmux-power-zoom.git ~/clone/path
```

Add this line to the bottom of `.tmux.conf`:

```tmux
run-shell ~/clone/path/power-zoom.tmux
```

Reload TMUX environment with `$ tmux source-file ~/.tmux.conf`, and that's it.

## Configuration options

Option | Default | Description
-|-|-
`@power_zoom_trigger` | Z | Key that triggers Power Zoom to toggle
`@power_zoom_without_prefix` | 0       | If set to 1, trigger key is independent of `<prefix>`
`@power_zoom_mouse`          | 0       | If set to 1, right double click toggles Power Zoom

## Contributing

Contributions are welcome, and they're appreciated. Every little bit
helps, and credit is always given.

The best way to send feedback is to file an issue at
https://github.com/jaclu/tmux-menus/issues

##### License

[MIT](LICENSE.md)
