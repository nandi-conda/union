import os
import sys
from pathlib import Path
from typing import final

# Select the Union Qt Quick Controls style before QtQuick loads.
_ = os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "org.kde.union")

from PySide6.QtCore import Property, QObject, Signal, Slot
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


def main() -> None:
    app = QGuiApplication(sys.argv)
    app.setApplicationName("union-demo")

    engine = QQmlApplicationEngine(app)
    # main.qml declares `required property var counter`.
    engine.setInitialProperties({"counter": Counter(app)})
    engine.load(Path(__file__).parent / "main.qml")
    if not engine.rootObjects():
        sys.exit(1)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
