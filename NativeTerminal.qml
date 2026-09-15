import QtQuick
import QMLTermWidget 2.0

Item {
  id: root
  required property string terminalTarget
  property color foreground: "#eeeeee"
  property color background: "#101010"
  property bool clientRunning: false
  property bool stopping: false
  property bool started: false
  property bool inputEnabled: true
  property alias terminalItem: terminal
  property alias terminalSession: session
  signal ended()

  function focusTerminal() {
    if (!stopping && clientRunning) terminal.forceActiveFocus()
  }

  function stop() {
    if (stopping) return
    stopping = true
    startup.stop()
    if (clientRunning) {
      session.sendSignal(15)
      stopTimeout.start()
    } else ended()
  }

  function applyPalette() {
    terminal.setBackgroundColor(background)
    terminal.setForegroundColor(foreground)
  }

  onForegroundChanged: applyPalette()
  onBackgroundChanged: applyPalette()
  Component.onCompleted: applyPalette()

  QMLTermWidget {
    id: terminal
    anchors.fill: parent
    enabled: root.clientRunning && !root.stopping && root.inputEnabled
    font.family: "monospace"
    font.pointSize: 10
    colorScheme: "cool-retro-term"
    session: QMLTermSession {
      id: session
      shellProgram: "/usr/bin/env"
      shellProgramArgs: ["python3", decodeURIComponent(Qt.resolvedUrl("bin/herdr-attach").toString().replace(/^file:\/\//, "")), root.terminalTarget]
      initialWorkingDirectory: "/"
      onStarted: {
        root.clientRunning = true
        root.focusTerminal()
      }
      onFinished: {
        root.clientRunning = false
        stopTimeout.stop()
        root.ended()
      }
    }
  }

  Timer {
    id: startup
    interval: 50
    running: root.width > 100 && root.height > 60 && !root.stopping && !root.started
    onTriggered: {
      root.started = true
      session.startShellProgram()
    }
  }

  Timer {
    id: stopTimeout
    interval: 1500
    onTriggered: if (root.clientRunning) session.sendSignal(9)
  }
}
