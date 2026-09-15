# Release status

Target repository: `kt3v/omarchy-herdr-hud-native` (public).
Plugin ID: `indie.herdr-hud`. Planned version: `0.1.0`.

## Verified locally

- Standalone runtime and tests; no original checkout or PoC required.
- Eleven Python tests, both JavaScript test files, and Omarchy manifest validation passed.
- Full-panel live acceptance passed using two owned disposable fixture panes.
- Basic filename and content scan found no credentials or user transcripts.
- Original MIT notice retained. No dependency implementation or binaries included.

## Remaining gates

- Resolve distribution obligations for the in-process QMLTermWidget dependency before public release. The installed Arch package identifies GPL-2.0-only. Upstream license contents have not yet been verified. Review the exact installed source revision and its file headers rather than assuming that separate installation removes GPL obligations.
- Create the public repository and initial commit after review; no repository has been created yet.
- Verify Omarchy Git-based installation without overwriting the active snapshot or enabling two HUDs.
- Publish the agreed release after installation verification.

Source references for the license review:

- https://github.com/Swordfish90/qmltermwidget
- https://www.gnu.org/licenses/gpl-faq.html#GPLAndPlugins

The current local directory is temporary. Preserve it in a permanent development directory before relying on it as the release source.
