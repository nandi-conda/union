"""Print every diagnostic Zed would show (ty for Python, qmllint for QML) as one
GitLab Code Quality JSON list on stdout. Exits 1 if there are any."""

import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).parent
QT = Path(os.environ["CONDA_PREFIX"]) / "lib" / "qt6"
# qmllint's levels mapped onto the severities ty uses for Code Quality.
QML_SEVERITY = {"info": "info", "warning": "minor", "critical": "major"}


def ty() -> list[dict[str, Any]]:
    out = subprocess.run(
        ["ty", "check", "--output-format", "gitlab"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    ).stdout
    return json.loads(out) if out.strip() else []


def qmllint() -> list[dict[str, Any]]:
    files = sorted(
        str(p.relative_to(ROOT))
        for p in ROOT.rglob("*.qml")
        if not any(part.startswith(".") for part in p.relative_to(ROOT).parts)
    )
    if not files:
        return []
    out = subprocess.run(
        [QT / "bin" / "qmllint", "-I", QT / "qml", "--json", "-", *files],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    ).stdout
    results: list[dict[str, Any]] = []
    for file in json.loads(out)["files"]:
        for w in file["warnings"]:
            line, column = w.get("line", 1), w.get("column", 1)
            check = f"qmllint/{w.get('id', w['type'])}"
            results.append(
                {
                    "check_name": check,
                    "description": f"{check}: {w['message']}",
                    "severity": QML_SEVERITY.get(w["type"], "minor"),
                    "fingerprint": hashlib.sha256(
                        f"{file['filename']}:{line}:{column}:{check}".encode()
                    ).hexdigest()[:16],
                    "location": {
                        "path": file["filename"],
                        "positions": {
                            "begin": {"line": line, "column": column},
                            "end": {
                                "line": line,
                                "column": column + w.get("length", 0),
                            },
                        },
                    },
                }
            )
    return results


def main() -> None:
    diagnostics = ty() + qmllint()
    json.dump(diagnostics, sys.stdout, indent=2)
    print()
    sys.exit(1 if diagnostics else 0)


if __name__ == "__main__":
    main()
