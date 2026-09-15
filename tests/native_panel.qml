import QtQuick
import QtTest
import Quickshell
import qs.Commons
import "plugin" as Native

Scope {
  id: root
  property int step: 0
  property int attempts: 0
  property int cycles: 0
  property string scrolledLine: ""
  property bool searchFound: false
  property bool alternateRequested: false
  readonly property var terminal: hud.terminalView.terminal
  readonly property string fixtureTarget: Quickshell.env("HERDR_NATIVE_TARGET")
  readonly property string otherTarget: Quickshell.env("HERDR_NATIVE_OTHER")

  function row(target, status, sequence) {
    return {pane_id: target, terminal_id: target, agent: "fixture", agent_status: status,
      workspace_label: "Safe acceptance", tab_label: "Native terminal", state_change_seq: sequence}
  }

  function check(value, detail) {
    if (value) { console.log("NATIVE_PASS", detail); return true }
    console.error("NATIVE_FAIL", detail)
    hud.close()
    finish.start()
    driver.stop()
    return false
  }

  function contains(text) {
    searchFound = false
    if (terminal) terminal.terminalSession.search(text)
    return searchFound
  }

  function screenshot(name) {
    var directory = Quickshell.env("HERDR_NATIVE_SCREENSHOTS")
    if (!directory) return
    var view = hud.viewForScreen(hud.panelScreenName)
    var surface = hud.opened ? view.panelSurface : view.alertSurface
    surface.grabToImage(function(image) {
      console.log("NATIVE_SCREENSHOT", image.saveToFile(directory + "/" + name + ".png"))
    })
  }

  Native.HerdrHud {
    id: hud
    monitorEnabled: false
    manifest: ({id: "indie.herdr-hud"})
  }
  TestCase { id: keys; name: "NativePanelKeys"; when: false; parent: hud.terminalView }
  Connections {
    target: root.terminal ? root.terminal.terminalSession : null
    function onMatchFound() { root.searchFound = true }
  }

  Timer { id: finish; interval: 1800; onTriggered: Qt.quit() }
  Timer { interval: 55000; running: true; onTriggered: root.check(false, "acceptance timeout") }
  Timer {
    id: driver
    interval: 650
    repeat: true
    running: true
    onTriggered: {
      if (root.step === 0) {
        hud.agents = [root.row(root.fixtureTarget, "working", 1), root.row(root.otherTarget, "idle", 1)]
        hud.connected = true
        hud.selectAgent(root.fixtureTarget)
        hud.openOnScreen(hud.defaultScreenName())
      } else if (root.step === 1) {
        if (!root.contains("LOG")) {
          if (++root.attempts > 10) root.check(false, "initial terminal frame: " + hud.terminalView.message)
          return
        }
        if (!root.check(root.terminal.terminalItem.columns > 30 && root.terminal.terminalItem.lines > 5, "panel geometry")) return
        hud.terminalView.focusTerminal()
      } else if (root.step === 2) {
        for (var key of [Qt.Key_1, Qt.Key_2, Qt.Key_3]) {
          keys.keyClick(key)
          keys.keyClick(Qt.Key_Return)
        }
        for (var key of [Qt.Key_Y, Qt.Key_E, Qt.Key_S]) keys.keyClick(key)
        keys.keyClick(Qt.Key_Return)
        for (var key of [Qt.Key_N, Qt.Key_O]) keys.keyClick(key)
        keys.keyClick(Qt.Key_Return)
        keys.keyClick(Qt.Key_Escape)
        keys.keyClick(Qt.Key_Return)
        if (!root.check(hud.opened, "Escape does not close HUD")) return
      } else if (root.step === 3) {
        if (!root.alternateRequested) {
          root.alternateRequested = true
          root.terminal.terminalSession.sendText("alt\r")
          return
        }
        if (!root.contains("SAFE TUI") || !root.contains("Redraw:")) {
          if (++root.attempts > 15) root.check(false, "native alternate screen in panel: " + root.terminal.terminalSession.history)
          return
        }
        root.check(true, "native alternate screen in panel")
        hud.uiMode = "omarchy"
        root.screenshot("native-omarchy")
        hud.rosterWidth = 290
      } else if (root.step === 4) {
        if (!root.check(root.contains("SAFE TUI"), "TUI survives panel resize")) return
        hud.uiMode = "wow"
      } else if (root.step === 5) {
        if (!root.check(root.contains("SAFE TUI") && hud.wowMode, "WoW switch preserves terminal")) return
        root.screenshot("native-wow")
        root.terminal.terminalSession.sendText("normal\r")
      } else if (root.step === 6) {
        hud.terminalView.focusTerminal()
        keys.keyClick(Qt.Key_PageUp)
      } else if (root.step === 7) {
        var match = root.terminal.terminalSession.history.match(/LOG\d+/)
        if (!root.check(!!match, "history visible")) return
        root.scrolledLine = match[0]
      } else if (root.step === 9) {
        var match = root.terminal.terminalSession.history.match(/LOG\d+/)
        if (!root.check(!!match && match[0] === root.scrolledLine, "history pinned during output")) return
        hud.terminalView.focusTerminal()
        keys.keyClick(Qt.Key_B, Qt.ControlModifier)
        hud.close()
      } else if (root.step === 10) {
        if (hud.terminalView.terminal) return
        if (!root.check(!hud.terminalView.clientRunning, "hidden panel releases attach with pending prefix")) return
        hud.alertBaseline = true
        hud.applyRoster(JSON.stringify({agents: [root.row(root.fixtureTarget, "blocked", 2), root.row(root.otherTarget, "idle", 1)]}), "", 0)
        if (!root.check(!!hud.activeAlert && !hud.opened, "hidden panel receives input notification")) return
        root.screenshot("native-alert")
        hud.openAlert(hud.defaultScreenName())
      } else if (root.step === 11) {
        if (!root.contains("LOG")) return
        if (!root.check(hud.selectedPane === root.fixtureTarget && !hud.activeAlert, "notification opens correct terminal")) return
        hud.selectAgent(root.otherTarget)
      } else if (root.step === 12) {
        if (!root.terminal || root.terminal.terminalTarget !== root.otherTarget || !root.contains("LOG")) return
        if (!root.check(hud.terminalView.currentTarget === root.otherTarget, "agent switch releases previous controller")) return
        root.terminal.terminalSession.sendText("SECOND_ONLY\r")
      } else if (root.step === 13) {
        if (hud.selectedPane !== root.fixtureTarget) {
          if (!root.contains("SECOND_ONLY")) return
          hud.selectAgent(root.fixtureTarget)
          return
        }
        if (!root.terminal || root.terminal.terminalTarget !== root.fixtureTarget || !root.contains("LOG")) return
        hud.close()
      } else if (root.step === 14) {
        if (hud.terminalView.terminal) return
        hud.openOnScreen(hud.defaultScreenName())
      } else if (root.step === 15) {
        if (!root.contains("LOG")) return
        if (++root.cycles < 5) { root.step = 13; return }
        root.check(true, "five hide/reopen cycles")
        hud.close()
      } else if (root.step === 16) {
        if (hud.terminalView.terminal) return
        hud.openOnScreen(hud.defaultScreenName())
      } else if (root.step === 17) {
        if (!root.contains("LOG")) return
        root.terminal.terminalSession.sendText("\u0002q")
      } else if (root.step === 18) {
        if (hud.terminalView.clientRunning) return
        if (!root.check(hud.terminalView.paused && !!root.terminal, "manual detach preserves final frame without reconnect loop")) return
        hud.terminalView.reconnect()
      } else if (root.step === 19) {
        if (!hud.terminalView.clientRunning || !root.contains("LOG")) return
        root.check(true, "explicit reconnect")
        hud.close()
      } else if (root.step === 20) {
        if (hud.terminalView.terminal) return
        console.log("NATIVE_TEST_COMPLETE")
        driver.stop()
        Qt.quit()
      }
      root.step++
    }
  }
}
