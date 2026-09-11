#!/usr/bin/env bash
# 基于 pi-gen 构建预安装了 PaperMC 的树莓派镜像
# 用法: bash build-custom.sh [output_dir]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STAGE_DIR="$ROOT/pi-gen/stage-mc"
PI_GEN_REPO="https://github.com/RPi-Distro/pi-gen.git"
WORK="${1:-$ROOT/pi-gen/work}"

mkdir -p "$WORK"

# 1. 克隆 pi-gen
if [[ ! -d "$WORK/pi-gen" ]]; then
  echo "==> 克隆 pi-gen ..."
  git clone --depth 1 "$PI_GEN_REPO" "$WORK/pi-gen"
fi

cd "$WORK/pi-gen"

# 2. 注入自定义 stage（在 stage2 之后执行，stage3/4/5 跳过）
#    stage2 = 基础系统（无桌面），足够跑 MC 服务器
echo "==> 注入 stage-mc ..."
rsync -a --delete "$STAGE_DIR/" "$WORK/pi-gen/stage-mc/"
# 跳过 stage3/4/5（桌面、X、推荐软件），只跑 stage0-2 + stage-mc
cat > SKIP <<'EOF'
stage3
stage4
stage5
EOF

# 3. 配置 build
cat > config <<'EOF'
IMG_NAME="mc-pi"
TARGET_HOSTNAME="mc-pi"
FIRST_USER_NAME="pi"
FIRST_USER_PASS=""
ENABLE_SSH=1
LOCALE_DEFAULT="en_US.UTF-8"
KEYBOARD_KEYMAP="us"
TIMEZONE_DEFAULT="Asia/Shanghai"
DEPLOY_COMPRESS="xz"
EOF

# 4. 构建（需要 Docker；pi-gen 会用 docker buildx）
echo "==> 开始构建（需要 Docker，首次约 30-60 分钟）..."
sudo bash ./build.sh

echo
echo "==> 完成。镜像位于: $WORK/pi-gen/deploy/"
ls -lh "$WORK/pi-gen/deploy/"
