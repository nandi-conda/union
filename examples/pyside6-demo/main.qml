pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
    id: window
    width: 800
    height: 560
    visible: true
    title: "Union + Kirigami"

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

    // A drawer entry that swaps the page stack to `page`.
    component PageAction: Kirigami.Action {
        required property Component page
        checked: (window.pageStack.currentItem as Kirigami.Page)?.title === text
        onTriggered: window.pageStack.replace(page)
    }

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

    globalDrawer: Kirigami.GlobalDrawer {
        isMenu: false
        modal: false
        collapsible: true
        actions: [
            PageAction { text: "Counter"; icon.name: "accessories-calculator"; page: counterPage },
            PageAction { text: "Controls"; icon.name: "configure"; page: controlsPage },
            PageAction { text: "Live"; icon.name: "media-playback-start"; page: livePage },
            PageAction { text: "List"; icon.name: "view-list-details"; page: listPage },
            Kirigami.Action { separator: true },
            Kirigami.Action {
                text: "About"
                icon.name: "help-about"
                onTriggered: about.open()
            }
        ]
    }

    pageStack.initialPage: counterPage

    Kirigami.PromptDialog {
        id: about
        title: "About"
        subtitle: "A PySide6 app styled by KDE Union, with Kirigami on top. The counter and the live waves are driven from Python."
        standardButtons: Kirigami.Dialog.Ok
    }

    Component {
        id: counterPage

        Kirigami.Page {
            title: "Counter"
            actions: [
                Kirigami.Action {
                    text: "Increment"
                    icon.name: "list-add"
                    onTriggered: window.counter.increment()
                },
                Kirigami.Action {
                    text: "Reset"
                    icon.name: "edit-reset"
                    enabled: window.counter.value > 0
                    onTriggered: window.counter.reset()
                }
            ]

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Kirigami.Units.largeSpacing

                Kirigami.Heading {
                    level: 1
                    text: "Clicked " + window.counter.value + " times"
                    Layout.alignment: Qt.AlignHCenter
                }

                QQC2.ProgressBar {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 16
                    value: window.counter.value % 11 / 10
                }

                Kirigami.InlineMessage {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 16
                    visible: window.counter.value >= 10
                    type: Kirigami.MessageType.Positive
                    text: "Ten clicks!"
                }
            }
        }
    }

    Component {
        id: controlsPage

        Kirigami.ScrollablePage {
            title: "Controls"

            Kirigami.FormLayout {
                QQC2.TextField {
                    Kirigami.FormData.label: "Text:"
                    placeholderText: "Type something…"
                }
                QQC2.ComboBox {
                    Kirigami.FormData.label: "Style:"
                    model: ["Breeze", "Union", "Qt"]
                }
                QQC2.SpinBox {
                    Kirigami.FormData.label: "Spin box:"
                    value: 42
                    editable: true
                }

                Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Choices" }

                QQC2.CheckBox {
                    Kirigami.FormData.label: "Check box:"
                    text: "Check me"
                    checked: true
                }
                QQC2.Switch {
                    Kirigami.FormData.label: "Switch:"
                    text: "Switch"
                }
                QQC2.RadioButton {
                    Kirigami.FormData.label: "Radio:"
                    text: "Option A"
                    checked: true
                }
                QQC2.RadioButton { text: "Option B" }
                RowLayout {
                    Kirigami.FormData.label: "Chips:"
                    Kirigami.Chip { text: "Union"; checked: true }
                    Kirigami.Chip { text: "Kirigami" }
                }

                Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Ranges" }

                QQC2.Slider {
                    Kirigami.FormData.label: "Slider:"
                    value: 0.5
                }
                QQC2.RangeSlider {
                    Kirigami.FormData.label: "Range:"
                    first.value: 0.25
                    second.value: 0.75
                }
                QQC2.Dial {
                    Kirigami.FormData.label: "Dial:"
                    implicitWidth: 72
                    implicitHeight: 72
                    value: 0.3
                }
            }
        }
    }

    // Driven by the Stats object in Python.
    Component {
        id: livePage

        Kirigami.Page {
            title: "Live"

            ColumnLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.largeSpacing

                Kirigami.Heading {
                    level: 2
                    text: "Animated from a Python QTimer · " + window.stats.clock
                    Layout.alignment: Qt.AlignHCenter
                }

                Waves {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    phase: window.stats.phase
                    accent: Kirigami.Theme.highlightColor
                }

                QQC2.ProgressBar { Layout.fillWidth: true; value: window.stats.wave }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Kirigami.Units.gridUnit
                    QQC2.BusyIndicator { running: true }
                    QQC2.Dial { enabled: false; value: window.stats.wave; implicitWidth: 80; implicitHeight: 80 }
                    Kirigami.Heading { level: 2; text: Math.round(window.stats.wave * 100) + " %" }
                }
            }
        }
    }

    Component {
        id: listPage

        Kirigami.ScrollablePage {
            title: "List"

            header: QQC2.Control {
                padding: Kirigami.Units.largeSpacing
                contentItem: Kirigami.SearchField {
                    placeholderText: "Filter " + window.allItems.length + " items…"
                    onTextChanged: window.filter = text
                }
            }

            footer: QQC2.Control {
                padding: Kirigami.Units.largeSpacing
                contentItem: QQC2.Label {
                    text: window.shownItems.length + " shown · clicking an item bumps the counter (" + window.counter.value + ")"
                    opacity: 0.7
                }
            }

            ListView {
                model: window.shownItems
                delegate: QQC2.ItemDelegate {
                    required property string modelData
                    width: ListView.view.width
                    text: modelData
                    onClicked: window.counter.increment()
                }
            }
        }
    }
}
