# Rex exports REX_BIN_DIR inside its panes; put its helper binaries first on PATH.
if [[ -n $REX_BIN_DIR ]]; then
    path=($REX_BIN_DIR $path)
fi
