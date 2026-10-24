# PySide6 + Union demo

A small PySide6 / QML app using the `org.kde.union` Qt Quick Controls style from
the `kde-union` package. It has three tabs: the common controls grouped by kind,
a Live tab of bars, a dial and a progress bar animated from a Python `QTimer`,
and a filterable list. A toolbar menu opens an About dialog.

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
- `pixi run check` type-checks with `ty`; `pixi run diagnostics` also runs
  `qmllint` and prints every diagnostic as one GitLab Code Quality JSON list.
