pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ApplicationWindow {
    id: window
    width: 760
    height: 560
    visible: true
    title: "Union + PySide6"

    // Set from Python via setInitialProperties; required properties instead of
    // context properties keep qmllint/qmlls from flagging unqualified access.
    required property var counter
    required property var stats

    readonly property var allItems: [
        "Breeze", "Union", "Oxygen", "Fusion", "Material", "Imagine", "Universal",
        "Kirigami", "Plasma", "Frameworks", "Qt Quick", "PySide6", "QML", "Controls"
    ]
    property string filter: ""
    readonly property var shownItems: allItems.filter(
        i => i.toLowerCase().indexOf(filter.toLowerCase()) >= 0)

    // Bars that ride a travelling sine wave.
    component Waves: RowLayout {
        id: waves
        property real phase: 0
        property color accent: "black"
        spacing: 2
        Repeater {
            model: 32
            Rectangle {
                required property int index
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignBottom
                Layout.preferredHeight: 8 + 200 * (Math.sin(waves.phase + index * 0.35) + 1) / 2
                radius: 3
                color: waves.accent
                opacity: 0.4 + 0.6 * index / 32
            }
        }
    }

    // A list whose rows all report clicks through one signal.
    component PickList: ListView {
        id: pickList
        signal picked
        clip: true
        ScrollBar.vertical: ScrollBar {}
        delegate: ItemDelegate {
            required property string modelData
            width: pickList.width
            text: modelData
            onClicked: pickList.picked()
        }
    }

    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 4

            Label {
                text: "Union + PySide6"
                font.bold: true
                font.pointSize: 13
            }
            Item { Layout.fillWidth: true }
            Label { text: window.stats.clock; opacity: 0.7 }
            ToolButton {
                text: "⋮"
                onClicked: menu.open()
                Menu {
                    id: menu
                    y: parent.height
                    MenuItem { text: "Reset counter"; onTriggered: window.counter.reset() }
                    MenuItem { text: "About"; onTriggered: about.open() }
                    MenuSeparator {}
                    MenuItem { text: "Quit"; onTriggered: Qt.quit() }
                }
            }
        }
    }

    footer: TabBar {
        id: tabs
        currentIndex: pages.currentIndex
        onCurrentIndexChanged: pages.currentIndex = currentIndex
        TabButton { text: "Controls" }
        TabButton { text: "Live" }
        TabButton { text: "List" }
    }

    Dialog {
        id: about
        title: "About"
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok
        Label {
            text: "A PySide6 app styled by KDE Union.\nThe counter and the live\nwaves are driven from Python."
        }
    }

    SwipeView {
        id: pages
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16
        currentIndex: tabs.currentIndex
        onCurrentIndexChanged: tabs.currentIndex = currentIndex

        // --- Controls ---
        GridLayout {
            columns: 2
            columnSpacing: 16
            rowSpacing: 16

            GroupBox {
                title: "Buttons"
                Layout.fillWidth: true
                Layout.fillHeight: true
                ColumnLayout {
                    anchors.fill: parent
                    Label {
                        text: "Clicked " + window.counter.value + " times"
                        font.pointSize: 16
                        Layout.alignment: Qt.AlignHCenter
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Button { text: "Increment"; highlighted: true; onClicked: window.counter.increment() }
                        Button { text: "Reset"; onClicked: window.counter.reset() }
                        Button { text: "Flat"; flat: true; ToolTip.visible: hovered; ToolTip.text: "A flat button" }
                    }
                    ProgressBar { Layout.fillWidth: true; value: window.counter.value % 11 / 10 }
                }
            }

            GroupBox {
                title: "Text"
                Layout.fillWidth: true
                Layout.fillHeight: true
                ColumnLayout {
                    anchors.fill: parent
                    TextField { Layout.fillWidth: true; placeholderText: "Type something…" }
                    ComboBox { Layout.fillWidth: true; model: ["Breeze", "Union", "Qt"] }
                    SpinBox { value: 42; editable: true }
                }
            }

            GroupBox {
                title: "Choices"
                Layout.fillWidth: true
                Layout.fillHeight: true
                ColumnLayout {
                    anchors.fill: parent
                    CheckBox { text: "Check me"; checked: true }
                    Switch { text: "Switch" }
                    RadioButton { text: "Option A"; checked: true }
                    RadioButton { text: "Option B" }
                }
            }

            GroupBox {
                title: "Ranges"
                Layout.fillWidth: true
                Layout.fillHeight: true
                ColumnLayout {
                    anchors.fill: parent
                    Slider { Layout.fillWidth: true; value: 0.5 }
                    RangeSlider { Layout.fillWidth: true; first.value: 0.25; second.value: 0.75 }
                    Dial { Layout.alignment: Qt.AlignHCenter; implicitWidth: 72; implicitHeight: 72; value: 0.3 }
                }
            }
        }

        // --- Live (driven by the Stats object in Python) ---
        ColumnLayout {
            spacing: 16

            Label {
                text: "Animated from a Python QTimer"
                font.pointSize: 14
                Layout.alignment: Qt.AlignHCenter
            }

            Waves {
                Layout.fillWidth: true
                Layout.fillHeight: true
                phase: window.stats.phase
                accent: window.palette.highlight
            }

            ProgressBar { Layout.fillWidth: true; value: window.stats.wave }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 24
                BusyIndicator { running: true }
                Dial { enabled: false; value: window.stats.wave; implicitWidth: 80; implicitHeight: 80 }
                Label { text: Math.round(window.stats.wave * 100) + " %"; font.pointSize: 18 }
            }
        }

        // --- List ---
        ColumnLayout {
            spacing: 8

            TextField {
                Layout.fillWidth: true
                placeholderText: "Filter " + window.allItems.length + " items…"
                onTextChanged: window.filter = text
            }

            PickList {
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: window.shownItems
                onPicked: window.counter.increment()
            }

            Label {
                text: window.shownItems.length + " shown · clicking an item bumps the counter (" + window.counter.value + ")"
                opacity: 0.7
            }
        }
    }
}
