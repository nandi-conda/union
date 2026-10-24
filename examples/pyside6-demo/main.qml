pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Particles
import QtQuick.Shapes
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
    id: window
    width: 900
    height: 600
    visible: true
    title: "Union + Kirigami · Animations"

    // Set from Python via setInitialProperties; required properties instead of
    // context properties keep qmllint/qmlls from flagging unqualified access.
    required property var counter
    required property var stats

    readonly property color accent: Kirigami.Theme.highlightColor
    readonly property color positive: Kirigami.Theme.positiveTextColor
    readonly property color negative: Kirigami.Theme.negativeTextColor

    // A drawer entry that swaps the first column to `page`, closing any pushed
    // detail pages first.
    component PageAction: Kirigami.Action {
        required property Component page
        checked: (window.pageStack.items[0] as Kirigami.Page)?.title === text
        onTriggered: {
            window.pageStack.pop(window.pageStack.items[0]);
            window.pageStack.replace(page);
        }
    }

    // A page that fades and slides up into place when it is created.
    component ShowPage: Kirigami.Page {
        id: showPage
        opacity: 0
        transform: Translate { id: lift; y: Kirigami.Units.gridUnit * 2 }
        Component.onCompleted: enter.start()
        ParallelAnimation {
            id: enter
            NumberAnimation { target: showPage; property: "opacity"; to: 1; duration: 350; easing.type: Easing.OutCubic }
            NumberAnimation { target: lift; property: "y"; to: 0; duration: 500; easing.type: Easing.OutBack }
        }
    }

    // A hover handler that counts as steering only while the pointer moves, so
    // a resting pointer hands control back to the page's own motion.
    component Steer: HoverHandler {
        id: steer
        property bool moving: false
        // Scene coordinates, so a page sliding under a still pointer is not a move.
        property point last
        onPointChanged: {
            const p = point.scenePosition;
            if (Math.abs(p.x - last.x) + Math.abs(p.y - last.y) < 2)
                return;
            last = p;
            moving = hovered;
            idle.restart();
        }
        property Timer idle: Timer {
            interval: 1500
            onTriggered: steer.moving = false
        }
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
            PageAction { text: "States"; icon.name: "media-playlist-shuffle"; page: statesPage },
            PageAction { text: "Easing"; icon.name: "office-chart-line"; page: easingPage },
            PageAction { text: "Springs"; icon.name: "transform-move"; page: springsPage },
            PageAction { text: "Particles"; icon.name: "games-highscores"; page: particlesPage },
            PageAction { text: "List"; icon.name: "view-list-details"; page: listPage },
            PageAction { text: "Live"; icon.name: "media-playback-start"; page: livePage },
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
        subtitle: "A PySide6 app styled by KDE Union, with Kirigami on top, showing off Qt Quick animation: behaviors, states and transitions, easing curves, springs, particles, list transitions and page pushes. The counter and the live waves are driven from Python."
        standardButtons: Kirigami.Dialog.Ok
    }

    // Python's counter, shown as a rolling number inside a springy ring.
    Component {
        id: counterPage

        ShowPage {
            id: page
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

            readonly property int value: window.counter.value
            // Rolls towards the real value, so the digits count up or down.
            property real shown: value
            Behavior on shown { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
            onValueChanged: pop.restart()

            Item {
                id: dial
                anchors.centerIn: parent
                width: Kirigami.Units.gridUnit * 14
                height: width

                // Fills a tenth per click and springs past its mark.
                property real fill: page.value % 10 / 10 || (page.value > 0 ? 1 : 0)
                Behavior on fill { SpringAnimation { spring: 3; damping: 0.15 } }

                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: Qt.alpha(Kirigami.Theme.textColor, 0.12)
                        strokeWidth: Kirigami.Units.gridUnit
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathAngleArc {
                            centerX: dial.width / 2; centerY: dial.height / 2
                            radiusX: dial.width / 2 - Kirigami.Units.gridUnit; radiusY: radiusX
                            startAngle: -90; sweepAngle: 360
                        }
                    }
                    ShapePath {
                        strokeColor: window.accent
                        strokeWidth: Kirigami.Units.gridUnit
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathAngleArc {
                            centerX: dial.width / 2; centerY: dial.height / 2
                            radiusX: dial.width / 2 - Kirigami.Units.gridUnit; radiusY: radiusX
                            startAngle: -90; sweepAngle: 360 * dial.fill
                        }
                    }
                }

                Kirigami.Heading {
                    id: number
                    anchors.centerIn: parent
                    level: 1
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 4
                    text: Math.round(page.shown)

                    // A squash-and-stretch pop on every change.
                    SequentialAnimation {
                        id: pop
                        NumberAnimation { target: number; property: "scale"; to: 1.35; duration: 90; easing.type: Easing.OutQuad }
                        NumberAnimation { target: number; property: "scale"; to: 1; duration: 500; easing.type: Easing.OutElastic }
                    }
                }
            }

            Kirigami.Heading {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: dial.bottom
                anchors.topMargin: Kirigami.Units.largeSpacing
                level: 3
                opacity: page.value >= 10 ? 1 : 0
                scale: page.value >= 10 ? 1 : 0.5
                Behavior on opacity { NumberAnimation { duration: 300 } }
                Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                text: "Lap " + Math.floor(page.value / 10) + " done!"
            }
        }
    }

    // One element, three states; the transition animates every property at once.
    Component {
        id: statesPage

        ShowPage {
            id: page
            title: "States"
            readonly property var names: ["left", "middle", "right"]
            property int at: 0
            actions: [
                Kirigami.Action {
                    text: "Next state"
                    icon.name: "go-next"
                    onTriggered: page.at = (page.at + 1) % 3
                },
                Kirigami.Action {
                    text: "Flip card"
                    icon.name: "object-flip-horizontal"
                    onTriggered: card.flipped = !card.flipped
                }
            ]

            Item {
                id: stage
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: parent.height * 0.55

                Rectangle {
                    id: orb
                    y: (stage.height - height) / 2
                    width: Kirigami.Units.gridUnit * 5
                    height: width
                    radius: width / 2
                    color: window.accent
                    state: page.names[page.at]

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: orb.color
                        shadowBlur: 1
                        shadowScale: 1.15
                    }

                    QQC2.Label {
                        anchors.centerIn: parent
                        text: orb.state
                        color: "white"
                        font.bold: true
                    }

                    TapHandler { onTapped: page.at = (page.at + 1) % 3 }

                    states: [
                        State {
                            name: "left"
                            PropertyChanges { orb.x: Kirigami.Units.gridUnit; orb.rotation: 0 }
                        },
                        State {
                            name: "middle"
                            PropertyChanges {
                                orb.x: (stage.width - orb.width) / 2
                                orb.width: Kirigami.Units.gridUnit * 9
                                orb.radius: Kirigami.Units.gridUnit
                                orb.rotation: 45
                                orb.color: window.positive
                            }
                        },
                        State {
                            name: "right"
                            PropertyChanges {
                                orb.x: stage.width - orb.width - Kirigami.Units.gridUnit
                                orb.width: Kirigami.Units.gridUnit * 3
                                orb.rotation: 180
                                orb.color: window.negative
                            }
                        }
                    ]
                    transitions: Transition {
                        ParallelAnimation {
                            NumberAnimation { properties: "x"; duration: 700; easing.type: Easing.InOutBack }
                            NumberAnimation { properties: "width,radius"; duration: 500; easing.type: Easing.OutBounce }
                            RotationAnimation { duration: 900; direction: RotationAnimation.Shortest; easing.type: Easing.OutElastic }
                            ColorAnimation { duration: 600 }
                        }
                    }
                }
            }

            // A card that flips in 3D between two faces.
            Flipable {
                id: card
                property bool flipped: false
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: stage.bottom
                width: Kirigami.Units.gridUnit * 16
                height: Kirigami.Units.gridUnit * 7

                front: Kirigami.AbstractCard {
                    anchors.fill: parent
                    contentItem: Kirigami.Heading {
                        level: 2
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "Tap to flip"
                    }
                }
                back: Kirigami.AbstractCard {
                    anchors.fill: parent
                    contentItem: QQC2.Label {
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.Wrap
                        text: "Flipable + Rotation transform, animated by a state transition."
                    }
                }

                transform: Rotation {
                    id: turn
                    origin.x: card.width / 2
                    origin.y: card.height / 2
                    axis { x: 0; y: 1; z: 0 }
                }
                states: State {
                    name: "back"
                    when: card.flipped
                    PropertyChanges { turn.angle: 180 }
                }
                transitions: Transition {
                    NumberAnimation { target: turn; property: "angle"; duration: 800; easing.type: Easing.OutBack }
                }

                TapHandler { onTapped: card.flipped = !card.flipped }
            }
        }
    }

    // The same journey under different easing curves.
    Component {
        id: easingPage

        ShowPage {
            id: page
            title: "Easing"
            readonly property var curves: [
                { name: "Linear", type: Easing.Linear },
                { name: "InOutQuad", type: Easing.InOutQuad },
                { name: "OutCubic", type: Easing.OutCubic },
                { name: "InOutExpo", type: Easing.InOutExpo },
                { name: "OutBack", type: Easing.OutBack },
                { name: "OutElastic", type: Easing.OutElastic },
                { name: "OutBounce", type: Easing.OutBounce },
                { name: "InOutCirc", type: Easing.InOutCirc }
            ]

            ColumnLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: page.curves

                    RowLayout {
                        id: lane
                        required property var modelData
                        required property int index
                        property real progress
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        SequentialAnimation on progress {
                            loops: Animation.Infinite
                            PauseAnimation { duration: 400 }
                            NumberAnimation { to: 1; duration: 1600; easing.type: lane.modelData.type }
                            PauseAnimation { duration: 600 }
                            NumberAnimation { to: 0; duration: 1600; easing.type: lane.modelData.type }
                        }

                        QQC2.Label {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                            text: lane.modelData.name
                            opacity: 0.8
                        }

                        Item {
                            id: track
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 2
                                color: Qt.alpha(Kirigami.Theme.textColor, 0.15)
                            }
                            // A trail that stretches behind the dot.
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: dot.x + dot.width / 2
                                height: 4
                                radius: 2
                                color: Qt.alpha(window.accent, 0.4)
                            }
                            Rectangle {
                                id: dot
                                anchors.verticalCenter: parent.verticalCenter
                                width: Kirigami.Units.gridUnit * 1.2
                                height: width
                                radius: width / 2
                                x: lane.progress * (track.width - width)
                                color: Qt.hsla(lane.index / page.curves.length, 0.65, 0.55, 1)
                            }
                        }
                    }
                }
            }
        }
    }

    // A swarm of dots on springs of different stiffness chasing one target.
    Component {
        id: springsPage

        ShowPage {
            id: page
            title: "Springs"
            property point target: Qt.point(width / 2, height / 2)

            // Wanders on its own until the pointer takes over.
            Timer {
                interval: 1400
                running: !hover.moving
                repeat: true
                triggeredOnStart: true
                onTriggered: page.target = Qt.point(
                    page.width * (0.15 + 0.7 * Math.random()),
                    page.height * (0.15 + 0.7 * Math.random()))
            }
            Steer {
                id: hover
                onPointChanged: if (moving) page.target = point.position
            }

            QQC2.Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Move the pointer here · each dot has its own spring and damping"
                opacity: 0.6
            }

            Repeater {
                model: 12

                Rectangle {
                    id: ball
                    required property int index
                    width: Kirigami.Units.gridUnit * (2.4 - index * 0.15)
                    height: width
                    radius: width / 2
                    color: Qt.hsla(0.55 + index * 0.05, 0.7, 0.55, 0.9)
                    x: page.target.x - width / 2
                    y: page.target.y - height / 2
                    z: index
                    Behavior on x { SpringAnimation { spring: 4 - ball.index * 0.28; damping: 0.12 + ball.index * 0.02; mass: 1 + ball.index * 0.1 } }
                    Behavior on y { SpringAnimation { spring: 4 - ball.index * 0.28; damping: 0.12 + ball.index * 0.02; mass: 1 + ball.index * 0.1 } }
                }
            }
        }
    }

    // Qt Quick Particles: an emitter tracing a Lissajous curve, or the pointer.
    Component {
        id: particlesPage

        ShowPage {
            id: page
            title: "Particles"
            padding: 0
            property real t
            NumberAnimation on t { from: 0; to: Math.PI * 2; duration: 8000; loops: Animation.Infinite }

            Rectangle {
                anchors.fill: parent
                color: "#10131a"
            }

            ParticleSystem { id: sparks }

            ImageParticle {
                system: sparks
                source: "qrc:///particleresources/glowdot.png"
                color: window.accent
                colorVariation: 0.35
                alpha: 0.6
                entryEffect: ImageParticle.Scale
            }

            Emitter {
                id: emitter
                system: sparks
                x: hover.moving ? hover.point.position.x : page.width / 2 + Math.sin(page.t * 3) * page.width * 0.35
                y: hover.moving ? hover.point.position.y : page.height / 2 + Math.sin(page.t * 2) * page.height * 0.3
                emitRate: 350
                lifeSpan: 1800
                lifeSpanVariation: 600
                size: 22
                sizeVariation: 10
                endSize: 4
                velocity: AngleDirection { angleVariation: 360; magnitude: 50; magnitudeVariation: 40 }
            }

            Gravity { system: sparks; magnitude: 30; angle: 90 }
            Turbulence { system: sparks; anchors.fill: parent; strength: 40 }

            Steer { id: hover }
        }
    }

    // Model changes animate through add, remove, move and displaced transitions.
    Component {
        id: listPage

        ShowPage {
            id: page
            title: "List"
            property int made: 0
            actions: [
                Kirigami.Action {
                    text: "Add"
                    icon.name: "list-add"
                    onTriggered: page.add()
                },
                Kirigami.Action {
                    text: "Remove"
                    icon.name: "list-remove"
                    enabled: fruit.count > 0
                    onTriggered: fruit.remove(Math.floor(Math.random() * fruit.count))
                },
                Kirigami.Action {
                    text: "Shuffle"
                    icon.name: "media-playlist-shuffle"
                    enabled: fruit.count > 1
                    onTriggered: shuffler.left = fruit.count
                }
            ]

            readonly property var names: ["Apple", "Banana", "Cherry", "Damson", "Elderberry", "Fig", "Grape", "Huckleberry", "Kiwi", "Lime", "Mango", "Nectarine"]

            function add(): void {
                const name = names[made % names.length];
                fruit.insert(Math.floor(Math.random() * (fruit.count + 1)), { name: name, hue: Math.random() });
                made++;
            }

            ListModel { id: fruit }
            Component.onCompleted: {
                for (let i = 0; i < 5; i++)
                    add();
            }

            // Moves one item at a time so the shuffle plays as a cascade.
            Timer {
                id: shuffler
                property int left: 0
                interval: 140
                running: left > 0
                repeat: true
                onTriggered: {
                    fruit.move(Math.floor(Math.random() * fruit.count), Math.floor(Math.random() * fruit.count), 1);
                    left--;
                }
            }

            ListView {
                anchors.fill: parent
                clip: true
                model: fruit
                spacing: Kirigami.Units.smallSpacing

                add: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 300 }
                    NumberAnimation { property: "scale"; from: 0.5; to: 1; duration: 450; easing.type: Easing.OutBack }
                }
                remove: Transition {
                    NumberAnimation { property: "opacity"; to: 0; duration: 300 }
                    NumberAnimation { property: "x"; to: -200; duration: 300; easing.type: Easing.InBack }
                }
                move: Transition {
                    NumberAnimation { properties: "x,y"; duration: 400; easing.type: Easing.OutCubic }
                }
                displaced: Transition {
                    NumberAnimation { properties: "x,y"; duration: 400; easing.type: Easing.OutCubic }
                    // An interrupted add can leave an item half-faded.
                    NumberAnimation { properties: "opacity,scale"; to: 1; duration: 300 }
                }

                delegate: QQC2.ItemDelegate {
                    id: row
                    required property string name
                    required property real hue
                    width: ListView.view.width
                    text: name
                    contentItem: RowLayout {
                        spacing: Kirigami.Units.largeSpacing
                        Rectangle {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 1.5
                            Layout.preferredHeight: Layout.preferredWidth
                            radius: width / 2
                            color: Qt.hsla(row.hue, 0.6, 0.55, 1)
                        }
                        QQC2.Label { text: row.name; Layout.fillWidth: true }
                        QQC2.Label { text: "Open ›"; opacity: 0.5 }
                    }
                    onClicked: window.pageStack.push(detailPage, { title: name, hue: hue })
                }
            }
        }
    }

    // Pushed as a second column; Kirigami slides it in.
    Component {
        id: detailPage

        ShowPage {
            id: page
            property real hue: 0

            Rectangle {
                id: hero
                anchors.centerIn: parent
                width: Kirigami.Units.gridUnit * 8
                height: width
                radius: width / 2
                color: Qt.hsla(page.hue, 0.6, 0.55, 1)
                scale: 0
                rotation: -90
                Component.onCompleted: grow.start()
                ParallelAnimation {
                    id: grow
                    SpringAnimation { target: hero; property: "scale"; to: 1; spring: 3; damping: 0.18 }
                    NumberAnimation { target: hero; property: "rotation"; to: 0; duration: 900; easing.type: Easing.OutBack }
                }

                Kirigami.Heading {
                    anchors.centerIn: parent
                    level: 2
                    color: "white"
                    text: page.title
                }
            }
        }
    }

    // Driven by the Stats object in Python.
    Component {
        id: livePage

        ShowPage {
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
                    accent: window.accent
                }

                Kirigami.Heading {
                    level: 2
                    text: Math.round(window.stats.wave * 100) + " %"
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}
