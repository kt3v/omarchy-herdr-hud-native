# Herdr HUD Native

Omarchy-only HUD plugin with native terminal input for Herdr agents.

## Requirements

- Omarchy with Quickshell and Hyprland/Wayland
- Herdr CLI available as `herdr`
- System package `qmltermwidget`

## Installation

Install through Omarchy:

```bash
omarchy pkg add qmltermwidget
omarchy plugin add https://github.com/kt3v/omarchy-herdr-hud-native.git --enable
```

Do not enable another Herdr HUD at the same time. The plugin stores its settings in `~/.config/herdr-hud-native/state.json`.

## Removal

Remove the plugin through Omarchy:

```bash
omarchy plugin remove indie.herdr-hud
```

This leaves the `qmltermwidget` system package and the settings file in
`~/.config/herdr-hud-native/state.json` in place. Remove them separately if
desired:

```bash
omarchy pkg drop qmltermwidget
rm -rf ~/.config/herdr-hud-native
```

## Features

- Native VT terminal attached to the selected Herdr agent
- Shift+drag selects terminal text; releasing the mouse copies it to the clipboard and clears the highlight
- Ctrl+Shift+V or Shift+Insert pastes the clipboard into the focused terminal; Ctrl+V remains available to terminal applications
- Approval-dialog keyboard input and TUI rendering
- Omarchy and WoW designs
- Agent switching, launcher, alerts, hidden-panel notifications
- Safe reconnect, disconnect, bounded read-only monitoring, and dependency errors

The plugin supports Omarchy only. It does not provide an HTML renderer, prompt bridge, legacy plugin migration, or independent chat history. Herdr owns terminal controller, resize, scroll, and alternate-screen behavior.

## Development

This checkout can be symlinked into `~/.config/omarchy/plugins/indie.herdr-hud`.
Edit the checkout, not a separate installed copy. Run `bin/dev-watch` in a
desktop terminal and leave it running. It watches QML, JavaScript, `manifest.json`,
and `qmldir`, groups save bursts, and restarts Omarchy shell once per burst.
Only one watcher can run for the checkout. Stop it with Ctrl-C.

The installed shell's `rescanPlugins` can retain cached QML, so the development
watcher deliberately uses `omarchy restart shell`. This briefly restarts all shell
UI and closes the HUD; it does not stop Herdr agents. Reopen the HUD afterwards.
For a manual refresh, run `omarchy restart shell`. Do not use `omarchy-shell -q`
to verify a reload: quiet mode reports success even when IPC fails.
Changes under `bin/` take effect on the next process start; restart `bin/dev-watch`
itself after editing the watcher. Run shell commands outside an isolated sandbox.

```bash
python3 -m unittest discover -s tests -v
node --test tests/*.mjs
omarchy plugin validate .
python3 tests/run-native-live --run-live --screenshots /tmp/herdr-release-panel
```

Live acceptance requires a Wayland session and Herdr. It creates disposable fixture panes and never sends input to existing agents.

## Licensing

The retained HUD code is MIT-licensed; see `LICENSE`. The launcher, designs, roster, and alert behavior derive from Alex Finn's `finna/omarchy-herdr-hud`; the original copyright notice is preserved.

MIT applies to this repository's own source files only, not to its runtime dependencies or an entire combined distribution. Dependency sources and binaries are not bundled. See [LICENSES.md](LICENSES.md) for dependency attribution, reviewed version information, and distribution scope.
