# Union looks up its styles (share/union/styles) through XDG_DATA_DIRS.
export _KDE_UNION_OLD_XDG_DATA_DIRS="${XDG_DATA_DIRS-}"
export XDG_DATA_DIRS="${CONDA_PREFIX}/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
