import QtQuick
import QtQuick.Shapes
import qs.Commons

// Nextcloud logo: a simple cloud glyph drawn with QtQuick Shapes.
// Uses the same pattern as the built-in DropboxIcon so it blends naturally
// with the bar theme.
Item {
  id: root

  property real iconSize: Style.font.icon
  property color color: Color.foreground

  width: iconSize
  height: iconSize * 0.75
  implicitWidth: iconSize
  implicitHeight: iconSize * 0.75

  // Cloud body
  Shape {
    anchors.fill: parent
    antialiasing: true
    layer.enabled: true
    layer.samples: 4

    ShapePath {
      fillColor: root.color
      strokeWidth: 0

      // Cloud outline (simplified rounded-top silhouette):
      // Start at bottom-left
      startX: root.width * 0.10; startY: root.height * 0.90

      // Bottom-left arc (left bump)
      PathArc {
        x: root.width * 0.10; y: root.height * 0.38
        radiusX: root.width * 0.22; radiusY: root.height * 0.40
        direction: PathArc.Clockwise
      }

      // Left bump top arc
      PathArc {
        x: root.width * 0.42; y: root.height * 0.18
        radiusX: root.width * 0.26; radiusY: root.height * 0.35
        direction: PathArc.Clockwise
      }

      // Center-top arc (main dome)
      PathArc {
        x: root.width * 0.62; y: root.height * 0.12
        radiusX: root.width * 0.22; radiusY: root.height * 0.30
        direction: PathArc.Clockwise
      }

      // Right bump top arc
      PathArc {
        x: root.width * 0.90; y: root.height * 0.42
        radiusX: root.width * 0.24; radiusY: root.height * 0.36
        direction: PathArc.Clockwise
      }

      // Right side down to bottom-right
      PathArc {
        x: root.width * 0.90; y: root.height * 0.90
        radiusX: root.width * 0.18; radiusY: root.height * 0.30
        direction: PathArc.Clockwise
      }

      // Bottom line back to start
      PathLine { x: root.width * 0.10; y: root.height * 0.90 }
    }
  }
}
