import QtQuick
import QtQuick.Window
import "../package/contents/ui"

// Runs the trail outside KWin, over a stand-in desktop with a scripted pointer,
// so the look can be checked without enabling the script.
Window {
    id: window
    width: 960
    height: 600
    visible: true
    color: "#1b1e24"

    property real t
    NumberAnimation on t { from: 0; to: Math.PI * 2; duration: 9000; loops: Animation.Infinite }
    // Moves for 3.5s, rests for 1.5s, like a real hand.
    property bool moving: (t / (Math.PI * 2) * 9000) % 5000 < 3500
    property point pointer
    onTChanged: if (moving)
        pointer = Qt.point(width / 2 + Math.sin(t * 3) * width * 0.36, height / 2 + Math.sin(t * 5) * height * 0.3)

    Rectangle {
        x: 80; y: 70; width: 420; height: 280; radius: 6
        color: "#2a2e36"; border.color: "#3b404a"
        Rectangle { width: parent.width; height: 32; radius: 6; color: "#31363f" }
    }
    Rectangle {
        x: 430; y: 230; width: 440; height: 300; radius: 6
        color: "#2a2e36"; border.color: "#3b404a"
        Rectangle { width: parent.width; height: 32; radius: 6; color: "#31363f" }
    }
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 44; color: "#20232a" }

    Sparks {
        anchors.fill: parent
        at: window.pointer
        emitting: window.moving
    }

    // A pointer arrow.
    Canvas {
        x: window.pointer.x; y: window.pointer.y; width: 16; height: 24
        onPaint: {
            const c = getContext("2d");
            c.fillStyle = "white"; c.strokeStyle = "black"; c.lineWidth = 1.2;
            c.beginPath(); c.moveTo(1, 1); c.lineTo(1, 19); c.lineTo(5.5, 15); c.lineTo(9, 22);
            c.lineTo(12, 20.5); c.lineTo(8.5, 14); c.lineTo(14, 14); c.closePath(); c.fill(); c.stroke();
        }
    }
}
