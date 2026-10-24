import QtQuick
import QtQuick.Particles

// The union demo's Particles page look, as a trail: sparks spawn at `at` while
// `emitting` is set. `lifetime` is how long the last spark takes to fade out.
Item {
    id: sparks

    property point at
    property bool emitting
    readonly property int lifetime: emitter.lifeSpan + emitter.lifeSpanVariation

    ParticleSystem { id: system }

    ImageParticle {
        system: system
        source: "qrc:///particleresources/glowdot.png"
        color: "#3daee9"
        colorVariation: 0.35
        alpha: 0.6
        entryEffect: ImageParticle.Scale
    }

    Emitter {
        id: emitter
        system: system
        enabled: sparks.emitting
        x: sparks.at.x
        y: sparks.at.y
        emitRate: 250
        lifeSpan: 900
        lifeSpanVariation: 300
        size: 16
        sizeVariation: 8
        endSize: 2
        velocity: AngleDirection { angleVariation: 360; magnitude: 40; magnitudeVariation: 30 }
    }

    Gravity { system: system; magnitude: 60; angle: 90 }
    Turbulence { system: system; anchors.fill: parent; strength: 30 }
}
