# PySide6 + Union demo

A small PySide6 / Kirigami app using the `org.kde.union` Qt Quick Controls style
from the `kde-union` package. A `Kirigami.ApplicationWindow` with a collapsible
global drawer switches between four pages: a Counter, the common controls in a
`Kirigami.FormLayout`, a Live page of bars, a dial and a progress bar animated
from a Python `QTimer`, and a filterable list. The drawer also opens an About dialog.
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
