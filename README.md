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

## Features

- Native VT terminal attached to the selected Herdr agent
- Approval-dialog keyboard input and TUI rendering
- Omarchy and WoW designs
- Agent switching, launcher, alerts, hidden-panel notifications
- Safe reconnect, disconnect, bounded read-only monitoring, and dependency errors

The plugin supports Omarchy only. It does not provide an HTML renderer, prompt bridge, legacy plugin migration, or independent chat history. Herdr owns terminal controller, resize, scroll, and alternate-screen behavior.

## Development

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
