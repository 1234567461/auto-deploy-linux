#!/bin/bash -e
# stage-mc: 在基础系统上预装 PaperMC 服务器 + systemd 服务
# 由 build-custom.sh 注入到 pi-gen 的 stage2 之后

# 安装 Java 21
on_chroot <<'EOF'
apt-get update
apt-get install -y --no-install-recommends openjdk-21-jre-headless ufw curl tmux
apt-get clean
EOF

# 部署 MC 服务器目录与脚本
install -d "${ROOTFS_DIR}/opt/mc-server/plugins"
install -d "${ROOTFS_DIR}/opt/mc-server/world"
install -m 0755 files/install-paper.sh "${ROOTFS_DIR}/opt/mc-server/install-paper.sh"
install -m 0644 files/server.properties "${ROOTFS_DIR}/opt/mc-server/server.properties"

# 首次启动时下载 PaperMC jar（构建时不联网下载，避免构建环境耦合版本）
install -m 0644 files/mcserver.service "${ROOTFS_DIR}/etc/systemd/system/mcserver.service"
install -m 0644 files/mc-firstboot.service "${ROOTFS_DIR}/etc/systemd/system/mc-firstboot.service"

# 安装 PaperMC systemd 单元，并通过 firstboot 在首次启动下载 jar
on_chroot <<'EOF'
systemctl enable mcserver.service
systemctl enable mc-firstboot.service
EOF

# 防火墙规则
install -m 0644 files/ufw.user.rules "${ROOTFS_DIR}/etc/ufw/user.rules" 2>/dev/null || true
