import QtQuick
import QtQuick.Window
import org.kde.kwin as KWin

// One click-through overlay per screen. Sparks spawn where the pointer is and
// only while it moves; the overlay hides once the last spark has faded, so an
// idle desktop costs nothing and fullscreen games keep direct scanout.
Item {
    id: root

    readonly property point cursor: KWin.Workspace.cursorPos
    property bool moving: false

    onCursorChanged: {
        moving = true;
        idle.restart();
    }

    Timer {
        id: idle
        interval: 80
        onTriggered: root.moving = false
    }

    Instantiator {
        model: KWin.Workspace.screens

        delegate: Window {
            id: overlay
            required property var modelData
            readonly property rect area: Qt.rect(modelData.geometry.x, modelData.geometry.y,
                                                 modelData.geometry.width, modelData.geometry.height)
            readonly property bool here: root.cursor.x >= area.x && root.cursor.x < area.x + area.width
                                         && root.cursor.y >= area.y && root.cursor.y < area.y + area.height
            readonly property bool _q_showWithoutActivating: true

            // WindowTransparentForInput makes KWin skip this window when hit
            // testing, so clicks go to whatever is underneath.
            flags: Qt.BypassWindowManagerHint | Qt.FramelessWindowHint
                   | Qt.WindowTransparentForInput | Qt.WindowDoesNotAcceptFocus
                   | Qt.WindowStaysOnTopHint
            color: "transparent"
            x: area.x
            y: area.y
            width: area.width
            height: area.height
            visible: trail.emitting || linger.running

            // Keeps the overlay up while the last sparks fade out.
            Timer { id: linger; interval: trail.lifetime }

            Sparks {
                id: trail
                anchors.fill: parent
                emitting: root.moving && overlay.here
                onEmittingChanged: if (!emitting) linger.restart()
                at: Qt.point(root.cursor.x - overlay.area.x, root.cursor.y - overlay.area.y)
            }
        }
    }
}
