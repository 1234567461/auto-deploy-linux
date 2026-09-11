#!/usr/bin/env bash
# 树莓派自动部署：烧录官方镜像到 SD 卡，并注入 cloud-init + Minecraft 服务器配置
set -euo pipefail

# 默认值
IMAGE=""
DEVICE=""
HOSTNAME="mc-pi"
WIFI_SSID=""
WIFI_PSK=""
SSH_KEY="${HOME}/.ssh/id_ed25519.pub"
MC_EULA="${MC_EULA:-false}"   # 设为 true 即接受 Minecraft EULA

usage() {
  cat <<EOF
用法: sudo $0 --image <path.img.xz> --device /dev/sdX [options]

必填:
  --image PATH        树莓派镜像路径 (.img 或 .img.xz)
  --device DEV        目标块设备，如 /dev/sdX 或 /dev/diskN (macOS)

可选:
  --hostname NAME     主机名，默认 mc-pi
  --wifi-ssid SSID    Wi-Fi SSID
  --wifi-psk PSK      Wi-Fi 密码
  --ssh-key PATH      注入的 SSH 公钥，默认 ~/.ssh/id_ed25519.pub
  --mc-eula BOOL      是否接受 Minecraft EULA (true/false)，默认 false
  -h                  显示帮助
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image)     IMAGE="$2"; shift 2 ;;
    --device)    DEVICE="$2"; shift 2 ;;
    --hostname)  HOSTNAME="$2"; shift 2 ;;
    --wifi-ssid) WIFI_SSID="$2"; shift 2 ;;
    --wifi-psk)  WIFI_PSK="$2"; shift 2 ;;
    --ssh-key)   SSH_KEY="$2"; shift 2 ;;
    --mc-eula)   MC_EULA="$2"; shift 2 ;;
    -h|--help)   usage ;;
    *) echo "未知参数: $1"; usage ;;
  esac
done

[[ -n "$IMAGE" && -n "$DEVICE" ]] || usage
[[ -f "$IMAGE" ]] || { echo "镜像文件不存在: $IMAGE"; exit 1; }
[[ -e "$DEVICE" ]] || { echo "目标设备不存在: $DEVICE"; exit 1; }

# 权限检查
if [[ $EUID -ne 0 ]]; then
  echo "需要 root 权限来写块设备，请用 sudo 运行"; exit 1
fi

# 依赖检查
for cmd in dd sgdisk; do
  command -v "$cmd" >/dev/null || { echo "缺少命令: $cmd"; exit 1; }
done
if command -v xz >/dev/null 2>&1; then XZ="xz"; else XZ="cat"; fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CI_DIR="$ROOT/rpi/cloud-init"

# 1. 烧录镜像
echo "==> [1/4] 烧录 $IMAGE -> $DEVICE ..."
case "$(uname -s)" in
  Darwin)
    diskutil unmountDisk "$DEVICE" || true
    if [[ "$IMAGE" == *.xz ]]; then
      $XZ -dc "$IMAGE" | dd of="$DEVICE" bs=4m conv=sync
    else
      dd if="$IMAGE" of="$DEVICE" bs=4m conv=sync
    fi
    diskutil eject "$DEVICE"
    diskutil mountDisk "$DEVICE"
    ;;
  Linux)
    sudo umount "${DEVICE}"?* 2>/dev/null || true
    if [[ "$IMAGE" == *.xz ]]; then
      $XZ -dc "$IMAGE" | sudo dd of="$DEVICE" bs=4M conv=fsync status=progress
    else
      sudo dd if="$IMAGE" of="$DEVICE" bs=4M conv=fsync status=progress
    fi
    sudo partprobe "$DEVICE" || true
    sleep 2
    ;;
esac

# 2. 定位 boot 分区 (FAT32)
BOOT_DEV=""
case "$(uname -s)" in
  Darwin) BOOT_DEV="$(ls -d /Volumes/boot* 2>/dev/null | head -1)" ;;
  Linux)  BOOT_DEV="$(lsblk -lnpo name "$DEVICE"1 2>/dev/null | head -1)"
          [[ -z "$BOOT_DEV" ]] && BOOT_DEV="${DEVICE}1"
          udisksctl mount -b "$BOOT_DEV" 2>/dev/null || sudo mount "$BOOT_DEV" /mnt
          BOOT_MNT="$(findmnt -no TARGET "$BOOT_DEV" 2>/dev/null || echo /mnt)"
          ;;
esac
[[ -n "${BOOT_MNT:-$BOOT_DEV}" ]] || { echo "未找到 boot 挂载点"; exit 1; }
BOOT_MNT="${BOOT_MNT:-$BOOT_DEV}"
echo "==> boot 分区挂载于: $BOOT_MNT"

# 3. 生成 cloud-init 文件 (注入到 boot 分区)
echo "==> [3/4] 生成 cloud-init 配置 ..."
SSH_PUBKEY="$(cat "$SSH_KEY" 2>/dev/null || echo "")"

mkdir -p "$BOOT_MNT"
# 拷贝模板
cp "$CI_DIR/meta-data"        "$BOOT_MNT/meta-data"
cp "$CI_DIR/network-config"   "$BOOT_MNT/network-config"

# 渲染 user-data（注入 hostname / ssh key / eula）
python3 - "$CI_DIR/user-data" "$BOOT_MNT/user-data" "$HOSTNAME" "$SSH_PUBKEY" "$MC_EULA" <<'PYEOF'
import sys, re
src, dst, hostname, pubkey, eula = sys.argv[1:6]
with open(src) as f: t = f.read()
t = t.replace("__HOSTNAME__", hostname)
t = t.replace("__SSH_PUBKEY__", pubkey or "# (no ssh key provided)")
t = t.replace("__MC_EULA__", "true" if eula.lower() == "true" else "false")
with open(dst, "w") as f: f.write(t)
print("   user-data 已渲染")
PYEOF

# Wi-Fi 凭证写入 network-config
if [[ -n "$WIFI_SSID" && -n "$WIFI_PSK" ]]; then
  cat > "$BOOT_MNT/network-config" <<EOF
version: 2
wifis:
  wlan0:
    dhcp4: true
    optional: true
    access-points:
      "$WIFI_SSID":
        password: "$WIFI_PSK"
EOF
  echo "   Wi-Fi 凭证已写入 network-config"
fi

# 4. 卸载
sync
case "$(uname -s)" in
  Darwin) diskutil eject "$DEVICE" ;;
  Linux)  sudo umount "$BOOT_MNT" 2>/dev/null || true ;;
esac

echo "==> [4/4] 完成。把 SD 卡插到树莓派上电即可。"
echo "    SSH:    ssh ${HOSTNAME}.local"
echo "    MC:     启动后约 5-10 分钟，端口 25565"
echo "    日志:   sudo journalctl -u cloud-init -f   (首次启动时)"
echo "           sudo journalctl -u mcserver -f      (服务运行时)"
