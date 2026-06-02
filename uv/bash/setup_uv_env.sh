#!/bin/bash

TARGET_DIR="$HOME/.uv_env"
TARGET_FILE="$TARGET_DIR/.command"
BASHRC="$HOME/.bashrc"
UV_CONFIG_DIR="$HOME/.config/uv"
UV_CONFIG_FILE="$UV_CONFIG_DIR/uv.toml"

# 安装 uv（如果未安装）
if ! command -v uv &> /dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    source "$HOME/.local/bin/env" 2>/dev/null || export PATH="$HOME/.local/bin:$PATH"
fi

# 配置 uv 使用阿里云镜像源
mkdir -p "$UV_CONFIG_DIR"
cat << 'TOML_EOF' > "$UV_CONFIG_FILE"
[[index]]
url = "http://mirrors.aliyun.com/pypi/simple/"
default = true
TOML_EOF

# 创建目标目录
mkdir -p "$TARGET_DIR"

# 写入函数定义
cat << 'INNER_EOF' > "$TARGET_FILE"
vc() {
    [ -z "$1" ] && { echo "Error: Please provide an environment name."; return 1; }
    local env_name="$1"
    local py_version="${2:-3.12}"
    local current_dir=$(pwd)
    mkdir -p "$HOME/.uv_env"
    cd "$HOME/.uv_env" && uv venv "$env_name" --python "$py_version"
    cd "$current_dir"
}

vl() {
    if [ -d "$HOME/.uv_env" ]; then
        ls -1 "$HOME/.uv_env"
    else
        echo "Error: ~/.uv_env directory does not exist"
    fi
}

va() {
    local env_name="${1:-Torch}"
    if [ -f "$HOME/.uv_env/$env_name/bin/activate" ]; then
        source "$HOME/.uv_env/$env_name/bin/activate"
    else
        echo "Error: Environment ~/.uv_env/$env_name not found"
    fi
}

alias vd="deactivate"

vr() {
    if [ -z "$1" ]; then
        echo "Error: Please provide an environment name."
        return 1
    fi
    
    local env_name="$1"
    local env_path="$HOME/.uv_env/$env_name"
    
    if [ ! -d "$env_path" ]; then
        echo "Error: Environment '$env_name' does not exist"
        echo "Use 'vl' to list available environments"
        return 1
    fi
    
    # 检查是否正在使用要删除的环境
    if [ -n "$VIRTUAL_ENV" ] && [ "$VIRTUAL_ENV" = "$env_path" ]; then
        echo "Error: Environment '$env_name' is currently active. Run 'deactivate' first."
        return 1
    fi
    
    echo "Removing environment: $env_name"
    echo "Path: $env_path"
    read -p "Are you sure you want to delete this environment? (y/N): " confirmation
    
    if [ "$confirmation" = "y" ] || [ "$confirmation" = "Y" ]; then
        rm -rf "$env_path"
        echo "Environment '$env_name' removed successfully"
    else
        echo "Deletion cancelled"
    fi
}

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

# 检查并添加到 .bashrc
CHECK_STR="source \"$TARGET_FILE\""

if ! grep -q "$CHECK_STR" "$BASHRC"; then
    cat << EOF >> "$BASHRC"

if [ -f "$TARGET_FILE" ]; then
    source "$TARGET_FILE"
fi
EOF
fi

# 重新加载 .bashrc
source $BASHRC