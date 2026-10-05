import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Reads Nextcloud sync state via busctl calls to the org.freedesktop.CloudProviders
// D-Bus interface exposed by the Nextcloud desktop client.
// CloudProviders Status codes:
//   0  IDLE     — everything up to date
//   1  SYNCING  — transfer in progress
//   2  ERROR    — something went wrong
//   3  PAUSED   — sync paused by user

Item {
  id: root

  // ── public state ────────────────────────────────────────────────────────────
  property bool installed:  false
  property bool running:    false
  property bool configured: false
  property int  syncStatus: -1     // -1=unknown, 0=idle, 1=syncing, 2=error, 3=paused
  property string statusText:  "Checking…"
  property string accountPath: ""
  property string accountName: ""
  property string lastError:   ""

  readonly property bool ok:      running && configured && syncStatus !== 2
  readonly property bool syncing: syncStatus === 1
  readonly property bool idle:    syncStatus === 0
  readonly property bool error:   syncStatus === 2
  readonly property bool paused:  syncStatus === 3

  // ── status refresh ──────────────────────────────────────────────────────────
  function refresh() {
    if (statusProc.running) return
    statusProc.command = [
      "sh", "-c",
      // 1. Check if the binary exists
      // 2. Check if the D-Bus service is registered
      // 3. Read the three CloudProviders properties we care about
      "set -e; " +
      "command -v nextcloud >/dev/null 2>&1 && echo INSTALLED || echo NOT_INSTALLED; " +
      "busctl --user status com.nextcloudgmbh.Nextcloud >/dev/null 2>&1 && echo RUNNING || echo NOT_RUNNING; " +
      "busctl --user get-property com.nextcloudgmbh.Nextcloud " +
        "/com/nextcloudgmbh/Nextcloud/Folder/0 " +
        "org.freedesktop.CloudProviders.Account Status 2>/dev/null || echo STATUS_NA; " +
      "busctl --user get-property com.nextcloudgmbh.Nextcloud " +
        "/com/nextcloudgmbh/Nextcloud/Folder/0 " +
        "org.freedesktop.CloudProviders.Account StatusDetails 2>/dev/null || echo DETAILS_NA; " +
      "busctl --user get-property com.nextcloudgmbh.Nextcloud " +
        "/com/nextcloudgmbh/Nextcloud/Folder/0 " +
        "org.freedesktop.CloudProviders.Account Path 2>/dev/null || echo PATH_NA; " +
      "busctl --user get-property com.nextcloudgmbh.Nextcloud " +
        "/com/nextcloudgmbh/Nextcloud/Folder/0 " +
        "org.freedesktop.CloudProviders.Account Name 2>/dev/null || echo NAME_NA"
    ]
    statusProc.running = true
  }

  function _applyOutput(raw) {
    var lines = raw.trim().split("\n").map(function(l) { return l.trim() })

    root.installed  = lines[0] === "INSTALLED"
    root.running    = lines[1] === "RUNNING"

    if (!root.installed) { root.statusText = "Not installed"; return }
    if (!root.running)   { root.statusText = "Not running";   return }

    var statusLine  = lines[2] || ""
    var detailsLine = lines[3] || ""
    var pathLine    = lines[4] || ""
    var nameLine    = lines[5] || ""

    if (statusLine === "STATUS_NA" || statusLine === "") {
      root.configured = false
      root.syncStatus = -1
      root.statusText = "Not configured"
      return
    }

    root.configured = true

    // busctl output format: "i <number>"
    var statusMatch = statusLine.match(/i\s+(\d+)/)
    root.syncStatus = statusMatch ? parseInt(statusMatch[1], 10) : -1

    // busctl output format: 's "some string"'
    function stripBusctl(line) {
      var m = line.match(/^s\s+"(.*)"$/)
      return m ? m[1] : ""
    }

    var details = stripBusctl(detailsLine)
    root.accountPath = stripBusctl(pathLine)
    root.accountName = stripBusctl(nameLine)

    if (details !== "" && details !== "DETAILS_NA") {
      var parts = details.split(" - ")
      root.statusText = parts.length >= 2 ? parts[parts.length - 1].trim() : details
    } else {
      var labels = ["Up to date", "Syncing…", "Error", "Paused"]
      root.statusText = (root.syncStatus >= 0 && root.syncStatus < labels.length)
        ? labels[root.syncStatus] : "Unknown"
    }
    root.lastError = ""
  }

  // ── startup + periodic polling ───────────────────────────────────────────────
  Timer {
    interval: 800
    running: true
    repeat: false
    onTriggered: root.refresh()
  }

  Timer {
    interval: 7000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  // ── Process ──────────────────────────────────────────────────────────────────
  Process {
    id: statusProc
    running: false
    command: []
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root._applyOutput(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (text.trim() !== "") root.lastError = text.trim().substring(0, 160)
      }
    }
  }
}
