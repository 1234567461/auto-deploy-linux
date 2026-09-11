#!/usr/bin/env bash
# 首次启动时下载 PaperMC jar（镜像不含 jar，保持镜像精简 + 免联网构建）
set -euo pipefail
MC_VERSION="${MC_VERSION:-1.21.4}"
DATA_DIR=/opt/mc-server
cd "$DATA_DIR"

PAPER_BUILD=$(curl -fsSL "https://api.papermc.io/v2/projects/paper/versions/$MC_VERSION" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['builds'][-1])")
URL="https://api.papermc.io/v2/projects/paper/versions/$MC_VERSION/builds/$PAPER_BUILD/downloads/paper-$MC_VERSION-$PAPER_BUILD.jar"
echo "下载 PaperMC: $URL"
curl -fSL -o paper.jar "$URL"
echo "eula=false" > eula.txt  # 用户首次启动需改 true
chown -R pi:pi /opt/mc-server
systemctl disable mc-firstboot.service
