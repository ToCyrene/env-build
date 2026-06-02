#!/bin/bash

TARGET_DIR="$HOME/.uv_env"
TARGET_FILE="$TARGET_DIR/.command"
BASHRC="$HOME/.bashrc"

rm -rf "$TARGET_DIR"

if [ -f "$BASHRC" ]; then
    sed -i "/if \[ -f \"${TARGET_FILE//\//\\/}\" \]; then/,/fi/d" "$BASHRC"
    sed -i '${/^[[:space:]]*$/d}' "$BASHRC"
fi

source $BASHRC