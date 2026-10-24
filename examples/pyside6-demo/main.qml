import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ApplicationWindow {
    id: window
    width: 420
    height: 360
    visible: true
    title: "Union + PySide6"

    // Set from Python via setInitialProperties; a required property instead of
    // a context property keeps qmllint/qmlls from flagging unqualified access.
    required property var counter

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Label {
            text: "Clicked " + window.counter.value + " times"
            font.pointSize: 16
            Layout.alignment: Qt.AlignHCenter
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Button { text: "Increment"; highlighted: true; onClicked: window.counter.increment() }
            Button { text: "Reset"; onClicked: window.counter.reset() }
        }

        TextField {
            Layout.fillWidth: true
            placeholderText: "Type something…"
        }

        RowLayout {
            CheckBox { text: "Check me"; checked: true }
            Switch { text: "Switch" }
            ComboBox { model: ["Breeze", "Union", "Qt"] }
        }

        Slider { Layout.fillWidth: true; value: 0.5 }
        ProgressBar { Layout.fillWidth: true; value: window.counter.value % 11 / 10 }

        Item { Layout.fillHeight: true }
    }
}
