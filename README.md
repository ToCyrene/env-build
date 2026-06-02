# env-build

安装 [uv](https://docs.astral.sh/uv/) 并仿照 conda 的方式管理 Python 虚拟环境。原生 `uv` 的环境散落在项目目录各处，本脚本将所有环境统一创建到 `~/.uv_env/` 下，便于集中查看和管理。

## 快速开始

### Linux / macOS

```bash
bash uv/bash/setup_uv_env.sh
source ~/.bashrc
```

### Windows (PowerShell)

```powershell
powershell -ExecutionPolicy Bypass -File uv/pwsh/setup_uv_env.ps1
```

## 命令

| 命令 | 说明 |
|------|------|
| `vc <name> [python_version]` | 创建虚拟环境（默认 Python 3.12） |
| `vl` | 列出所有环境 |
| `va [name]` | 激活环境（默认 `Torch`） |
| `vd` | 退出当前环境 |

## 卸载

```bash
bash uv/bash/reset.sh           # Linux/macOS
powershell uv/pwsh/uninstall_uv_env.ps1   # Windows
```
