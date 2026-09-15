# Licensing and runtime dependencies

## Project source

This repository's own QML, Python, and JavaScript source files are provided under the MIT License in [LICENSE](LICENSE). The original copyright notice from Alex Finn's [finna/omarchy-herdr-hud](https://github.com/finna/omarchy-herdr-hud) is retained.

The manifest's MIT designation covers these plugin source files only. It does not relicense dependencies or claim that an entire combined distribution is MIT-licensed.

## Distribution scope

This repository distributes plugin source and tests. It does not bundle dependency source code, libraries, executables, or a preassembled runtime. Users install runtime dependencies separately through their system.

The plugin imports QMLTermWidget into the Quickshell process. Separate installation and QML source format should not be treated as blanket exemptions from applicable license conditions. Anyone redistributing dependencies or a combined package must assess and satisfy the applicable licenses, including notices and source-provision requirements where relevant.

This document records attribution and review findings for this source release. It is not a legal opinion about every possible downstream distribution.

## QMLTermWidget

- Upstream: https://github.com/Swordfish90/qmltermwidget
- Reviewed revision: [ce8e09ad4daeb9fe59b60d6b228b0f7cf4055e16](https://github.com/Swordfish90/qmltermwidget/tree/ce8e09ad4daeb9fe59b60d6b228b0f7cf4055e16), identified in the supplied release review as the source of Arch package `qmltermwidget 2.0.0.git1-1`.
- The supplied review identifies GPL-2.0-or-later headers in `TerminalDisplay` and `KSession`, exposed as `QMLTermWidget` and `QMLTermSession`. Other files carry LGPL or BSD notices; their individual terms remain applicable.
- Arch package metadata reports GPL-2.0-only. This attribution records the reviewed source-header findings rather than silently treating the package label as authoritative for every source file.
- License files at the reviewed revision: [GPL](https://github.com/Swordfish90/qmltermwidget/blob/ce8e09ad4daeb9fe59b60d6b228b0f7cf4055e16/LICENSE), [LGPL](https://github.com/Swordfish90/qmltermwidget/blob/ce8e09ad4daeb9fe59b60d6b228b0f7cf4055e16/LICENSE.LGPL2+), and [BSD](https://github.com/Swordfish90/qmltermwidget/blob/ce8e09ad4daeb9fe59b60d6b228b0f7cf4055e16/LICENSE.BSD-3-clause).

QMLTermWidget is not bundled with this repository.

## Quickshell

- Upstream: https://git.outfoxxed.me/quickshell/quickshell
- License: GNU LGPL v3. This document does not infer permission to use later license versions merely from the standard license text.
- License text: https://www.gnu.org/licenses/lgpl-3.0.html

Quickshell is supplied by the user's Omarchy installation and is not bundled here. No special QML licensing exception is assumed by this release.

## Other runtime requirements

Qt and Hyprland are provided by the Omarchy environment. Herdr runs as a separate executable invoked by the plugin. These components are not bundled or relicensed by this repository; consult each installed component's own license notices when redistributing it.
