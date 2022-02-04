# tmux-power-zoom

Zoom pane to separate window, and unzoom back into original location

Popup menus to help with managing your environment.

## Purpose

Quite often when I zoom a pane, work in it for a while and then figure out I need to open a pane to check something I have completely forgotten I am working in a zoomed pane, so as I open a new pane the new pane suddenly becomes squeezed in next to the original pane, often far to small to be practicaly usable.

This plugin zooms panes into a new window, so that it is convenient to open support panes. Hitting Smart Zoom again will move the pane back to it's original location, if no other panes are present the temp window is closed. 

The temp window is named using title and ID of the zoomed pane, so that if other panes were open and it is left running, it will later be a hint as the pupose of that window.

## Usage

Once installed, hit the trigger to get the main menu to popup.
Default is ``` <prefix> Z ``` see Configuration below for how to change it.

## Install

### Installation with [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) (recommended)

Add plugin to the list of TPM plugins in `.tmux.conf`:

    set -g @plugin 'jaclu/tmux-power-zoom'

Hit `prefix + I` to fetch the plugin and source it. That's it!

### Manual Installation

Clone the repo:

    $ git clone https://github.com/jaclu/tmux-power-zoom ~/clone/path

Add this line to the bottom of `.tmux.conf`:

    run-shell ~/clone/path/power-zoom.tmux

Reload TMUX environment with `$ tmux source-file ~/.tmux.conf`, and that's it.

## Configuration

### Changing the key-bindings for this plugin

The default trigger is `<prefix> Z`. Trigger is selected like this:
 
```
set -g @power_zoom_trigger Z
```

This enables Power zoom when pane is double-clicked with the right mouse button

```
set -g @power_zoom_mouse 1
```

## Compatability

| Version| Notice |
| -------| ------------- |
| 3.2 -   | Fully compatible  |
| 3.0 - 3.1c | Menu centering not supported, will be displayed top left if C is used as menu location. <br>Additionally some actions might not work depending on version. <br> There should be a notification message about "unknown command" in such casses. |


## Contributing

Contributions are welcome, and they are greatly appreciated! Every little bit helps, and credit will always be given.

The best way to send feedback is to file an issue at https://github.com/jaclu/tmux-menus/issues


##### License

[MIT](LICENSE.md)
