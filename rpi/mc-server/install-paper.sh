#!/usr/bin/env bash
# 独立运行的 PaperMC 安装脚本（与 cloud-init/user-data 中的版本保持一致）
# 用法: MC_VERSION=1.21.4 MC_EULA=true bash install-paper.sh
set -euo pipefail

MC_VERSION="${MC_VERSION:-1.21.4}"
DATA_DIR="${DATA_DIR:-/opt/mc-server}"

mkdir -p "$DATA_DIR/plugins" "$DATA_DIR/world"
cd "$DATA_DIR"

PAPER_BUILD=$(curl -fsSL "https://api.papermc.io/v2/projects/paper/versions/$MC_VERSION" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['builds'][-1])")

URL="https://api.papermc.io/v2/projects/paper/versions/$MC_VERSION/builds/$PAPER_BUILD/downloads/paper-$MC_VERSION-$PAPER_BUILD.jar"
echo "下载 PaperMC: $URL"
curl -fSL -o paper.jar "$URL"

echo "eula=${MC_EULA:-false}" > eula.txt
echo "完成: $DATA_DIR/paper.jar (MC $MC_VERSION, build $PAPER_BUILD)"
