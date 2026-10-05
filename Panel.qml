import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "maximilian-maag.nextcloud"
  ipcTarget: "maximilian-maag.nextcloud"
  manageIpc: false

  readonly property color foreground:  bar ? bar.foreground : Color.foreground
  readonly property color urgent:      bar ? bar.urgent     : Color.urgent
  readonly property color dim:         Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  // Icon tint
  readonly property color barIconColor: {
    if (!nc.running)   return Qt.darker(barForeground, 1.7)
    if (nc.error)      return root.urgent
    if (nc.paused)     return Qt.darker(barForeground, 1.4)
    return barForeground
  }

  // Spinning animation while syncing
  property real spinAngle: 0
  RotationAnimation on spinAngle {
    from: 0; to: 360
    duration: 2400
    loops: Animation.Infinite
    running: nc.syncing
    easing.type: Easing.Linear
  }

  implicitWidth:  button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: if (opened) {
    nc.refresh()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  // ── Nextcloud service ────────────────────────────────────────────────────────
  Service {
    id: nc
  }

  IpcHandler {
    target: root.ipcTarget
    function open():    void   { root.open() }
    function close():   void   { root.close() }
    function toggle():  void   { root.toggle() }
    function refresh(): string { nc.refresh(); return "ok" }
    function status():  string { return nc.statusText }
  }

  // ── Bar button ───────────────────────────────────────────────────────────────
  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    iconComponent: Component {
      Item {
        NextcloudIcon {
          anchors.centerIn: parent
          iconSize: Style.space(12)
          color: root.barIconColor
          rotation: nc.syncing ? root.spinAngle : 0
          Behavior on color { ColorAnimation { duration: 180 } }
        }
      }
    }
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) {
        Quickshell.execDetached(["uwsm-app", "--", "nextcloud"])
      } else {
        root.toggle()
      }
    }
  }

  // ── Popup panel ─────────────────────────────────────────────────────────────
  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth:  panel.fittedContentWidth(Style.space(320))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(400))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === "o" || t === "O") {
          root.close()
          Quickshell.execDetached(["uwsm-app", "--", "nextcloud"])
        } else if (t === "r" || t === "R") {
          nc.refresh()
        }
      }

      Column {
        id: column
        width: parent.width
        spacing: Style.space(12)
        padding: Style.space(12)

        // ── Hero ──────────────────────────────────────────────────────────────
        PanelHero {
          width: column.width - column.padding * 2
          title: nc.accountName !== "" ? nc.accountName : "Nextcloud"
          meta:  nc.statusText
          foreground: root.foreground
          fontFamily: root.fontFamily
          iconComponent: Component {
            NextcloudIcon {
              iconSize: Style.font.display
              color: root.foreground
              opacity: nc.running ? 1.0 : 0.4
            }
          }
        }

        // ── Status row ────────────────────────────────────────────────────────
        Row {
          width: column.width - column.padding * 2
          spacing: Style.space(8)

          Rectangle {
            width:  Style.space(8)
            height: Style.space(8)
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            color: {
              if (!nc.running)   return root.dim
              if (nc.error)      return root.urgent
              if (nc.syncing)    return "#4fc3f7"
              if (nc.paused)     return Qt.darker(root.foreground, 1.4)
              return "#66bb6a"
            }
            Behavior on color { ColorAnimation { duration: 220 } }
          }

          Text {
            textFormat: Text.PlainText
            text: {
              if (!nc.installed)  return "Nextcloud is not installed"
              if (!nc.running)    return "Daemon not running"
              if (!nc.configured) return "Not configured — click to set up"
              return nc.statusText
            }
            color: nc.error ? root.urgent : root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            elide: Text.ElideRight
            width: parent.width - parent.children[0].width - parent.spacing
          }
        }

        // ── Error detail ──────────────────────────────────────────────────────
        Text {
          textFormat: Text.PlainText
          visible: nc.lastError !== ""
          width: column.width - column.padding * 2
          text: nc.lastError
          color: root.urgent
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        // ── Account path ──────────────────────────────────────────────────────
        Text {
          textFormat: Text.PlainText
          visible: nc.accountPath !== ""
          width: column.width - column.padding * 2
          text: nc.accountPath
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideMiddle
        }

        PanelSeparator {
          foreground: root.foreground
          width: column.width - column.padding * 2
        }

        // ── Actions ──────────────────────────────────────────────────────────
        Column {
          width: column.width - column.padding * 2
          spacing: Style.space(6)

          ActionRow {
            label: nc.configured ? "Open Nextcloud" : "Set up Nextcloud"
            hint:  nc.configured ? "Show sync panel" : "Run the setup wizard"
            iconText: ""
            onActivated: {
              root.close()
              Quickshell.execDetached(["uwsm-app", "--", "nextcloud"])
            }
          }

          ActionRow {
            visible: nc.accountPath !== ""
            label: "Open sync folder"
            hint: "Browse files in Nautilus"
            iconText: ""
            onActivated: {
              root.close()
              Quickshell.execDetached(["uwsm-app", "--", "nautilus", nc.accountPath])
            }
          }
        }
      }
    }
  }

  // ── Shared action-row component ───────────────────────────────────────────────
  component ActionRow: CursorSurface {
    id: actionRow
    property string label:    ""
    property string hint:     ""
    property string iconText: ""
    signal activated()

    foreground: root.foreground
    implicitHeight: actionContent.implicitHeight + Style.spacing.rowPaddingX

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: actionRow.activated()
    }

    RowLayout {
      id: actionContent
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(10)
      spacing: Style.space(8)

      Text {
        text: actionRow.iconText
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.icon
        Layout.alignment: Qt.AlignVCenter
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(1)

        Text {
          textFormat: Text.PlainText
          Layout.fillWidth: true
          text: actionRow.label
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          elide: Text.ElideRight
        }

        Text {
          textFormat: Text.PlainText
          Layout.fillWidth: true
          visible: actionRow.hint !== ""
          text: actionRow.hint
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }
      }
    }
  }
}
