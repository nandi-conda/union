# Particle Trail (prototype)

A KWin script (declarative QML, no compiling) that draws the union demo's
particle sparks behind the mouse pointer on Plasma 6.

It opens one click-through overlay window per screen inside KWin, reads the
pointer from `Workspace.cursorPos`, and only shows the overlay while the
pointer moves and the sparks fade out.

## Install

    kpackagetool6 --type=KWin/Script --install package/
    kwriteconfig6 --file kwinrc --group Plugins --key particletrailEnabled true
    qdbus6 org.kde.KWin /KWin reconfigure

Or enable it in System Settings, Window Management, KWin Scripts.
Upgrade with `--upgrade package/`, remove with `--remove particletrail`.

## Preview without installing

`preview/preview.qml` runs the same `Sparks.qml` over a stand-in desktop with
a scripted pointer:

    qml6 preview/preview.qml

## Notes

- The sparks are the union demo's Particles page (`examples/pyside6-demo`),
  moved into `package/contents/ui/Sparks.qml`.
- Needs Plasma 6 (KWin 6.x). Tested to load and track the pointer in a
  headless KWin 6.8.1; that test had no GPU, so the in-KWin look is unverified.
- The particle simulation runs on KWin's main thread. Keep `emitRate` modest.
