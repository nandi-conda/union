import os
import sys
from pathlib import Path
from typing import final

# Select the Union Qt Quick Controls style before QtQuick loads.
_ = os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "org.kde.union")

import math
import time

from PySide6.QtCore import Property, QObject, QTimer, Signal, Slot
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine


@final
class Counter(QObject):
    changed = Signal()

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._value: int = 0

    @Property(int, notify=changed)
    def value(self) -> int:
        return self._value

    @Slot()
    def increment(self) -> None:
        self._value += 1
        self.changed.emit()

    @Slot()
    def reset(self) -> None:
        self._value = 0
        self.changed.emit()


@final
class Stats(QObject):
    """Ticks ~30 times a second so the Live tab has something to animate."""

    ticked = Signal()

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._start = time.monotonic()
        self._timer = QTimer(self)
        _ = self._timer.timeout.connect(self.ticked)
        self._timer.start(33)

    def _elapsed(self) -> float:
        return (time.monotonic() - self._start) * 2.0

    @Property(float, notify=ticked)
    def phase(self) -> float:
        return self._elapsed()

    @Property(float, notify=ticked)
    def wave(self) -> float:
        return (math.sin(self._elapsed()) + 1) / 2

    @Property(str, notify=ticked)
    def clock(self) -> str:
        return time.strftime("%H:%M:%S")


def main() -> None:
    app = QGuiApplication(sys.argv)
    app.setApplicationName("union-demo")

    engine = QQmlApplicationEngine(app)
    # main.qml declares `required property var counter` and `stats`.
    engine.setInitialProperties({"counter": Counter(app), "stats": Stats(app)})
    engine.load(Path(__file__).parent / "main.qml")
    if not engine.rootObjects():
        sys.exit(1)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
