"""Generate the rattler-build recipes for the KDE Frameworks 6 Union needs.

Packages are named kf6-<framework> so they never collide with conda-forge's KF5
packages of the same upstream name (kconfig 5.76 and so on). Everything builds
against QT below, the Qt that conda-forge's PySide6 is built with, so Union
loads into a pixi PySide6.

Run `pixi run gen` after changing this file, and commit the regenerated recipes.
"""

from pathlib import Path

import yaml

KF_VERSION = "6.31.0"
QT = "6.11.2.*"
ROOT = Path(__file__).resolve().parent.parent

COMMON_ARGS = [
    "-DBUILD_TESTING=OFF",
    "-DBUILD_QCH=OFF",
    "-DBUILD_PYTHON_BINDINGS=OFF",
    "-DBUILD_DESIGNERPLUGIN=OFF",
]

# upstream name -> (host deps, extra cmake args), in build order.
KF = {
    "extra-cmake-modules": ([], []),
    "kconfig": ([], []),
    "kcoreaddons": (["util-linux"], []),
    "kguiaddons": (["xorg-libx11", "libxcb"], ["-DWITH_WAYLAND=OFF"]),
    "ki18n": (["gettext", "libintl-devel", "iso-codes"], []),
    "kwidgetsaddons": ([], []),
    "karchive": (["zlib", "bzip2", "xz", "zstd", "openssl"], []),
    "kcolorscheme": (["kf6-kconfig", "kf6-kguiaddons", "kf6-ki18n"], []),
    "kiconthemes": (
        ["kf6-karchive", "kf6-kcolorscheme", "kf6-kconfig", "kf6-ki18n", "kf6-kwidgetsaddons"],
        # Breeze icons come from the desktop; bundling them is hundreds of MB.
        ["-DUSE_BreezeIcons=OFF"],
    ),
    "kirigami": ([], []),
}


def pkg_name(upstream: str) -> str:
    return "kf6-ecm" if upstream == "extra-cmake-modules" else f"kf6-{upstream}"


def recipe(upstream: str, deps: list[str], cmake_args: list[str]) -> dict:
    name = pkg_name(upstream)
    is_ecm = upstream == "extra-cmake-modules"
    build = ["${{ compiler('c') }}", "${{ compiler('cxx') }}", "${{ stdlib('c') }}", "cmake", "ninja", "pkg-config"]
    host = []
    if not is_ecm:
        build.append("python")
        host = ["kf6-ecm", f"qt6-main {QT}", "libgl-devel", "libopengl-devel", *deps]
    args = " ".join(["-DCMAKE_BUILD_TYPE=Release", *COMMON_ARGS, *cmake_args])
    script = [
        "cmake -GNinja -S . -B build $CMAKE_ARGS "
        '-DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_PREFIX_PATH="$PREFIX" -DCMAKE_INSTALL_LIBDIR=lib '
        f"{args}",
        "cmake --build build",
        "cmake --install build",
    ]
    reqs: dict = {"build": build, "host": host}
    if not is_ecm:
        reqs["run_exports"] = [f"${{{{ pin_subpackage('{name}', upper_bound='x.x') }}}}"]
    return {
        "context": {"version": KF_VERSION},
        "package": {"name": name, "version": "${{ version }}"},
        "source": {"git": f"https://github.com/KDE/{upstream}.git", "tag": f"v{KF_VERSION}"},
        "build": {"number": 0, "script": script, **({"noarch": "generic"} if is_ecm else {})},
        "requirements": reqs,
        "about": {
            "homepage": f"https://invent.kde.org/frameworks/{upstream}",
            "license": "LGPL-2.0-or-later" if upstream != "extra-cmake-modules" else "BSD-3-Clause",
            "summary": f"KDE Frameworks 6: {upstream}",
        },
    }


def main() -> None:
    order = []
    for upstream, (deps, args) in KF.items():
        name = pkg_name(upstream)
        d = ROOT / "recipes" / name
        d.mkdir(parents=True, exist_ok=True)
        # rattler-build picks up a variants.yaml next to the recipe.
        (d / "variants.yaml").write_text((ROOT / "variants.yaml").read_text())
        (d / "recipe.yaml").write_text(yaml.safe_dump(recipe(upstream, deps, args), sort_keys=False, width=200))
        order.append(name)
    order.append("cxx-rust-cssparser")
    (ROOT / "recipes" / "ORDER").write_text("\n".join(order) + "\n")
    print("wrote", len(order), "recipes")


if __name__ == "__main__":
    main()
