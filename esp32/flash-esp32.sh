#!/usr/bin/env bash
# ESP32-S3 最小 Linux 自动烧录
# 使用 paulneja/Linux-on-esp32-S3 的预构建镜像（Xtensa 原生 Linux 6.11 + WiFi）
set -euo pipefail

PORT="${PORT:-/dev/ttyACM0}"
SPEED=921600
REPO_URL="https://github.com/paulneja/Linux-on-esp32-S3.git"
CLONE_DIR="${CLONE_DIR:-esp32-linux-src}"

usage() {
  cat <<EOF
用法: $0 [--port /dev/ttyACM0] [--speed 921600]

选项:
  --port DEV     串口设备，默认 \$PORT 或 /dev/ttyACM0
  --speed N      烧录波特率，默认 921600
  --clone-only   只克隆源码不烧录
  -h             显示帮助

说明:
  - 首次运行会 git clone 上游仓库并安装 esptool
  - 烧录使用上游的 flash.sh（写入完整 flash 镜像）
  - 烧录后通过 telnet 或串口连接，详见 esp32/README.md
  - ESP32 上的 Linux 无法运行 Minecraft，仅作 Linux-on-MCU 实验
EOF
  exit 1
}

CLONE_ONLY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --port)       PORT="$2"; shift 2 ;;
    --speed)      SPEED="$2"; shift 2 ;;
    --clone-only) CLONE_ONLY=1; shift ;;
    -h|--help)    usage ;;
    *) echo "未知参数: $1"; usage ;;
  esac
done

# 1. esptool
if ! command -v esptool.py >/dev/null 2>&1; then
  echo "==> 安装 esptool ..."
  pip install --user esptool 2>/dev/null || pip3 install --user esptool
fi

# 2. 克隆上游
if [[ ! -d "$CLONE_DIR" ]]; then
  echo "==> 克隆 $REPO_URL ..."
  git clone --depth 1 "$REPO_URL" "$CLONE_DIR"
fi

if [[ $CLONE_ONLY -eq 1 ]]; then
  echo "==> --clone-only：源码已就绪于 $CLONE_DIR，跳过烧录"
  exit 0
fi

# 3. 烧录
echo "==> 烧录到 $PORT @ $SPEED ..."
cd "$CLONE_DIR"
# 上游 flash.sh 默认走 esptool，环境变量可覆盖端口/速率
ESPPORT="$PORT" ESPSPEED="$SPEED" bash ./flash.sh

echo
echo "==> 完成。串口连接: screen $PORT 115200"
echo "    WiFi 起来后可 telnet <esp32-ip> 登录（参见 README.md）"
