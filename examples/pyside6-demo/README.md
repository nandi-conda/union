# PySide6 + Union demo

A small PySide6 / Kirigami app using the `org.kde.union` Qt Quick Controls style
from the `kde-union` package, built to show off Qt Quick animation. A
`Kirigami.ApplicationWindow` with a collapsible global drawer switches between
pages that each fade and slide in:

- **Counter**: the Python counter as a rolling number (`Behavior` +
  `NumberAnimation`) with an elastic pop, inside a `Shape` ring that springs to
  its mark (`SpringAnimation`).
- **States**: one element with three `State`s whose `Transition` animates
  position, size, rotation and colour with different easings, plus a 3D
  `Flipable` card and a `MultiEffect` glow.
- **Easing**: the same trip under eight easing curves, side by side.
- **Springs**: a swarm of dots on springs of different stiffness chasing the
  pointer (or a wandering target when the pointer rests).
- **Particles**: a `QtQuick.Particles` emitter tracing a Lissajous curve, or
  following the pointer, with gravity and turbulence.
- **List**: a `ListModel` whose add, remove, move and displaced transitions
  animate; clicking a row pushes a detail page that Kirigami slides in as a
  second column.
- **Live**: bars riding a sine wave driven from a Python `QTimer`.

The drawer also opens an About dialog.
`kde-union` ships Kirigami's platform plugin, so Kirigami picks up Union's theme
and units (`kf6-kirigami` comes from the same channel).

```bash
pixi run demo
```

- `main.py` selects the style with `QT_QUICK_CONTROLS_STYLE=org.kde.union` before
  QtQuick loads, then hands a `Counter` and a ticking `Stats` to `main.qml` as required properties.
- The `demo` task runs on X11 (`QT_QPA_PLATFORM=xcb`) because conda-forge's Mesa
  has no Wayland EGL; the env ships its own Mesa for software GL.
- The `demo` task also sets `QT_QPA_PLATFORMTHEME=xdgdesktopportal`. The env has
  no KDE platform theme plugin, and without a KDE-looking theme KF6 applies the
  stock BreezeDark scheme and ignores the accent colour in `~/.config/kdeglobals`.
- Icons only show if an icon theme is installed on the host; the env has none.
- `pixi run check` type-checks with `ty`; `pixi run diagnostics` also runs
  `qmllint` and prints every diagnostic as one GitLab Code Quality JSON list.
- `.zed/settings.json` (repo root) makes Zed use ty instead of basedpyright/pyright.
