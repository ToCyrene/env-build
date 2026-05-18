#!/bin/bash

TARGET_DIR="$HOME/.uv_env"
TARGET_FILE="$TARGET_DIR/.command"
BASHRC="$HOME/.bashrc"

if ! command -v uv &> /dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    source "$HOME/.local/bin/env" 2>/dev/null || export PATH="$HOME/.local/bin:$PATH"
fi

mkdir -p "$TARGET_DIR"

cat << 'INNER_EOF' > "$TARGET_FILE"
vc() {
    [ -z "$1" ] && { echo "Error: Please provide an environment name."; return 1; }
    local env_name="$1"
    local py_version="${2:-3.12}"
    local current_dir=$(pwd)
    mkdir -p "$HOME/.env"
    cd "$HOME/.env" && uv venv "$env_name" --python "$py_version"
    cd "$current_dir"
}

vl() {
    if [ -d "$HOME/.env" ]; then
        ls -1 "$HOME/.env"
    else
        echo "Error: ~/.env directory does not exist"
    fi
}

va() {
    local env_name="${1:-Torch}"
    if [ -f "$HOME/.env/$env_name/bin/activate" ]; then
        source "$HOME/.env/$env_name/bin/activate"
    else
        echo "Error: Environment ~/.env/$env_name not found"
    fi
}

alias vd="deactivate"

unalias pip 2>/dev/null
unalias pip3 2>/dev/null

pip() {
    if [ "$1" = "install" ] && [ -z "$VIRTUAL_ENV" ]; then
        echo "Error: You are NOT in a virtual environment. 'pip install' is blocked!"
        echo "Please activate an environment first using 'va [name]' or create one via 'vc'."
        return 1
    fi
    uv pip "$@"
}

pip3() {
    pip "$@"
}
INNER_EOF

CHECK_STR="source \"$TARGET_FILE\""

if ! grep -q "$CHECK_STR" "$BASHRC"; then
    cat << EOF >> "$BASHRC"

if [ -f "$TARGET_FILE" ]; then
    source "$TARGET_FILE"
fi
EOF
fi